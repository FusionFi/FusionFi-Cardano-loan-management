use aiken/builtin.{if_then_else}
use aiken/collection/dict
use aiken/collection/list
use cardano/address.{Credential, Script, VerificationKey}
use cardano/assets.{AssetName, PolicyId}
use cardano/transaction.{InlineDatum, Output, Transaction}
use ccfl/helpersv3 as h
use ccfl/interestcalcs.{
  interestPayment, interestSlope1, interestSlope2, utilisationRatio,
}
use ccfl/typesv3.{
  CollateralDatum, InterestDatum, LoanDatum, MerkelConfigDatum, OracleDatum,
  WithdrawAction,
}

validator repay(pkh: ByteArray, op: PolicyId, cp: PolicyId) {
  withdraw(r: WithdrawAction, _cred: Credential, tx: Transaction) {
    let Transaction { inputs, outputs, reference_inputs, .. } = tx

    let cDatum: MerkelConfigDatum = h.get_config_datum(reference_inputs, cp)

    let iDatum: InterestDatum =
      h.get_interest_datum(reference_inputs, op, cDatum.interestVal)

    let oracleIns =
      list.filter(
        tx.inputs,
        fn(input) {
          input.output.address.payment_credential == Script(op) && list.has(
            assets.policies(input.output.value),
            op,
          )
        },
      )

    let oracleOuts =
      list.filter(
        tx.outputs,
        fn(output) {
          output.address.payment_credential == Script(op) && list.has(
            assets.policies(output.value),
            op,
          )
        },
      )

    let (oracleIn, oIn, oracleOut, oOut) = h.getOracleIO(oracleIns, oracleOuts)

    let exchangeRate = oOut.exchange

    let utilisation = utilisationRatio(oOut.borrowed, oOut.supply)

    h.merkelTx(
      fn(collateral, loan) {
        let loanToken = assets.without_lovelace(loan.value)

        expect InlineDatum(datum) = collateral.datum
        expect colDatum: CollateralDatum = datum
        expect InlineDatum(datum) = loan.datum
        expect loanDatum: LoanDatum = datum

        let (lin, cin) =
          h.get_loan_col_in_datum(
            inputs,
            loanToken,
            cDatum.loanVal,
            cDatum.colVal,
          )

        let adaOut = assets.lovelace_of(collateral.value)
        let exchangeAdjustment = loanDatum.amount * 1000
        let expectedCollateral = exchangeAdjustment / exchangeRate
        let minCollateralValue = expectedCollateral * 2
        let expectedOracle = assets.from_asset(op, loanDatum.oracle, 1)

        let interestCalc =
          if_then_else(
            utilisation <= iDatum.optimal,
            interestSlope1(
              iDatum.base,
              iDatum.optimal,
              iDatum.slope1,
              oOut.supply,
              oOut.borrowed,
            ),
            interestSlope2(
              iDatum.base,
              iDatum.optimal,
              iDatum.slope1,
              iDatum.slope2,
              oOut.supply,
              oOut.borrowed,
            ),
          )

        let interestTimeframe = oOut.timestamp - lin.timestamp
        let interestRequirement =
          interestPayment(interestTimeframe, lin.amount, interestCalc)
        let interestPaymentValue = interestRequirement / exchangeRate

        expect Some(payment) =
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

        expect InlineDatum(datum) = payment.datum
        expect pDatum: AssetName = datum

        expect [Pair(loanName, 1)] =
          loanToken |> assets.tokens(cDatum.loanVal) |> dict.to_pairs()

        and {
          pDatum == loanName,
          adaOut >= minCollateralValue,
          oracleOut == expectedOracle,
          loanDatum.amount <= lin.amount,
          colDatum.amount == loanDatum.amount * 2,
          loanDatum.timestamp == oOut.timestamp,
        }
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
