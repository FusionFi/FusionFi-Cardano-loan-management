use aiken/builtin.{if_then_else}
use aiken/collection/list
use cardano/address.{Credential, Script, VerificationKey}
use cardano/assets.{PolicyId}
use cardano/transaction.{InlineDatum, Input, Output, Transaction}
use ccfl/helpers.{merkelTx}
use ccfl/interestcalcs.{
  interestPayment, interestSlope1, interestSlope2, utilisationRatio,
}
use ccfl/types.{
  CollateralDatum, InterestDatum, LoanDatum, MerkelConfigDatum, OracleDatum,
  WithdrawRedeemer,
}

validator repay(pkh: ByteArray, p: PolicyId, cp: PolicyId) {
  withdraw(r: WithdrawRedeemer, _cred: Credential, tx: Transaction) {
    let Transaction { inputs, outputs, reference_inputs, .. } = tx

    expect Some(configIn) =
      list.find(
        reference_inputs,
        fn(input) { list.has(assets.policies(input.output.value), cp) },
      )

    expect InlineDatum(datum) = configIn.output.datum
    expect cDatum: MerkelConfigDatum = datum

    expect Some(interestRef) =
      list.find(
        reference_inputs,
        fn(input) {
          list.has(assets.policies(input.output.value), p) && input.output.address.payment_credential == Script(
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
          list.has(assets.policies(output.value), p) && output.address.payment_credential == Script(
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
        let loanToken = assets.without_lovelace(loan.value)
        expect InlineDatum(datum) = collateral.datum
        expect colDatum: CollateralDatum = datum
        expect InlineDatum(datum) = loan.datum
        expect loanDatum: LoanDatum = datum
        expect Some(loanIn) =
          list.find(
            inputs,
            fn(in) {
              in.output.address.payment_credential == loan.address.payment_credential && assets.without_lovelace(
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
              in.output.address.payment_credential == collateral.address.payment_credential && assets.without_lovelace(
                in.output.value,
              ) == loanToken
            },
          )
        expect InlineDatum(datum) = colIn.output.datum
        expect cin: CollateralDatum = datum
        let adaOut = assets.lovelace_of(collateral.value) + colDatum.yield
        let exchangeAdjustment = loanDatum.amount * 1000
        let expectedCollateral = exchangeAdjustment / exchangeRate
        let minCollateralValue = expectedCollateral * 2
        let expectedOracle = assets.from_asset(p, loanDatum.oracle, 1)
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
        let interestTimeframe = rDatum.timestamp - lin.timestamp
        let interestRequirement =
          interestPayment(interestTimeframe, lin.amount, interestCalc)
        let interestPaymentValue = interestRequirement / exchangeRate
        expect Some(_payment) =
          list.find(
            outputs,
            fn(output) {
              // we need to validate the pkh here -> either param or configDatum
              // times 10 to convert to lovelace value
              output.address.payment_credential == VerificationKey(pkh) && assets.lovelace_of(
                output.value,
              ) >= interestPaymentValue
            },
          )
        (adaOut >= minCollateralValue)? && cin.yield == colDatum.yield && (assets.without_lovelace(
          oracleOut.value,
        ) == expectedOracle)? && (loanDatum.amount <= lin.amount)? && colDatum.amount == loanDatum.amount * 2 && (loanDatum.timestamp == rDatum.timestamp)?
      },
      r.a,
      outputs,
    )
    // True
  }

  else(_) {
    fail
  }
}
