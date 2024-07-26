use aiken/builtin.{if_then_else}
use aiken/list
use aiken/string
use aiken/transaction.{
  InlineDatum, Input, Output, ScriptContext, Transaction, WithdrawFrom,
  placeholder,
}
use aiken/transaction/credential.{ScriptCredential}
use aiken/transaction/value.{PolicyId}
use ccfl/helpers.{merkelTx}
use ccfl/interestcalcs.{
  interestPayment, interestSlope1, interestSlope2, utilisationRatio,
}
use ccfl/types.{
  CollateralDatum, InterestDatum, LoanDatum, MerkelConfigDatum, OracleDatum,
  WithdrawRedeemer,
}
use tests/tools as t
use tests/transactions as tx

// staking validators that check the full transaction scope.

// Merkel Balance validates the whole transaction for the Balance redeemer case
// it combines both the merkel-loan && merkel-collateral cases together

validator(p: PolicyId, cp: PolicyId) {
  fn repay(r: WithdrawRedeemer, c: ScriptContext) {
    // True
    expect ScriptContext {
      transaction,
      purpose: WithdrawFrom(_stake_credential),
    } = c

    let Transaction { inputs, outputs, reference_inputs, .. } = transaction

    expect Some(configIn) =
      list.find(
        reference_inputs,
        fn(input) { list.has(value.policies(input.output.value), cp) },
      )

    expect InlineDatum(datum) = configIn.output.datum
    expect cDatum: MerkelConfigDatum = datum

    expect Some(interestRef) =
      list.find(
        reference_inputs,
        fn(input) {
          list.has(value.policies(input.output.value), p) && input.output.address.payment_credential == ScriptCredential(
            cDatum.interestVal,
          )
        },
      )

    expect InlineDatum(datum) = interestRef.output.datum
    expect iDatum: InterestDatum = datum
    expect Some(oracleOut) =
      list.find(
        outputs,
        fn(output) {
          list.has(value.policies(output.value), p) && output.address.payment_credential == ScriptCredential(
            cDatum.oracleVal,
          )
        },
      )

    expect InlineDatum(datum) = oracleOut.datum
    expect rDatum: OracleDatum = datum

    let exchangeRate = rDatum.exchange

    let utilisation = utilisationRatio(rDatum.borrowed, rDatum.supply)

    merkelTx(
      fn(collateral, loan) {
        let loanToken = value.without_lovelace(loan.value)
        expect InlineDatum(datum) = collateral.datum
        expect colDatum: CollateralDatum = datum
        expect InlineDatum(datum) = loan.datum
        expect loanDatum: LoanDatum = datum
        expect Some(loanIn) =
          list.find(
            inputs,
            fn(in) {
              in.output.address.payment_credential == loan.address.payment_credential && value.without_lovelace(
                in.output.value,
              ) == loanToken
            },
          )
        expect InlineDatum(datum) = loanIn.output.datum
        expect lin: LoanDatum = datum
        expect Some(colIn) =
          list.find(
            inputs,
            fn(in) {
              in.output.address.payment_credential == collateral.address.payment_credential && value.without_lovelace(
                in.output.value,
              ) == loanToken
            },
          )
        expect InlineDatum(datum) = colIn.output.datum
        expect cin: CollateralDatum = datum

        let adaOut = value.lovelace_of(collateral.value)
        let exchangeAdjustment = loanDatum.amount * 1000
        let expectedCollateral = exchangeAdjustment / exchangeRate
        let minCollateralValue = expectedCollateral * 2
        let expectedOracle = value.from_asset(p, loanDatum.oracle, 1)

        let interestCalc =
          if_then_else(
            utilisation <= iDatum.optimal,
            interestSlope1(
              iDatum.base,
              iDatum.optimal,
              iDatum.slope1,
              rDatum.supply,
              rDatum.borrowed,
            ),
            interestSlope2(
              iDatum.base,
              iDatum.optimal,
              iDatum.slope1,
              iDatum.slope2,
              rDatum.supply,
              rDatum.borrowed,
            ),
          )
        trace string.from_int(interestCalc)

        let interestTimeframe = rDatum.timestamp - lin.timestamp
        trace string.from_int(interestTimeframe)

        let interestRequirement =
          interestPayment(interestTimeframe, lin.amount, interestCalc)

        let interestPaymentValue = interestRequirement / exchangeRate
        trace string.from_int(interestPaymentValue)

        expect Some(payment) =
          list.find(
            outputs,
            fn(output) {
              // times 10 to convert to lovelace value
              value.lovelace_of(output.value) >= interestPaymentValue
            },
          )

        (adaOut >= minCollateralValue)? && (value.without_lovelace(
          oracleOut.value,
        ) == expectedOracle)? && (loanDatum.amount <= lin.amount)? && colDatum.amount == loanDatum.amount * 2 && (loanDatum.timestamp == rDatum.timestamp)?
      },
      r.a,
      outputs,
    )
  }
}

test repay_interest() {
  let inRatio = 2
  let outRatio = 2

  let inLoanAmount = 1000
  let inCollateralAmount = 1000
  let inCollateralValue = 2000

  let outLoanAmount = 500
  let outCollateralAmount = 1000
  let outCollateralValue = 2000

  let base = 55
  let optimal = 70
  let slope1 = 40
  let slope2 = 300
  let supply = 1000000
  let borrowed = 200000
  let utilisation = 1000000 / 200000

  let test_owner = #"face"

  let interest =
    if_then_else(
      utilisation <= optimal,
      interestSlope1(base, optimal, slope1, supply, borrowed),
      interestSlope2(base, optimal, slope1, slope2, supply, borrowed),
    )

  trace string.from_int(interest)

  // withdrawl
  let withdraw0 = tx.withdrawal(t.merkelRepay)

  let bRedeemer = tx.withdrawRedeemer([0])

  let loanIn1 = tx.mLoanInput(1, inLoanAmount)
  let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue)

  let userIn1 = tx.userInput(2000000)
  let configIn = tx.configInput()
  let interestIn = tx.interestInput()
  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let loanOut1 = tx.mLoanOutput(outLoanAmount)
  let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue)
  let interestOut = tx.interestOutput(interest)

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn, interestIn],
      extra_signatories: [test_owner],
      inputs: [colIn1, loanIn1, oracleIn, userIn1],
      outputs: [colOut1, loanOut1, oracleOut, interestOut],
      withdrawals: withdraw0,
    }

  let ctx = tx.wCtx(t.merkelRepay, tx)

  repay(t.oracleMintHash, t.configMintHash, bRedeemer, ctx)?
}
