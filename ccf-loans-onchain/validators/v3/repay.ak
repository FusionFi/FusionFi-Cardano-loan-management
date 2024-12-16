use aiken/builtin.{if_then_else}
use aiken/collection/dict
use aiken/collection/list
use cardano/address.{Credential, VerificationKey}
use cardano/assets.{AssetName, PolicyId}
use cardano/transaction.{InlineDatum, Output, Transaction}
use ccfl/helpers
use ccfl/interestcalcs.{
  interestPayment, interestSlope1, interestSlope2, utilisationRatio,
}
use ccfl/types.{
  CollateralDatum, InterestDatum, LoanDatum, MerkelConfigDatum, OracleDatum,
  WithdrawRedeemer,
}

validator repay(pkh: ByteArray, op: PolicyId, cp: PolicyId) {
  withdraw(r: WithdrawRedeemer, _cred: Credential, tx: Transaction) {
    let Transaction { inputs, outputs, reference_inputs, .. } = tx

    let cDatum: MerkelConfigDatum =
      helpers.get_config_datum(reference_inputs, cp)

    let iDatum: InterestDatum =
      helpers.get_interest_datum(reference_inputs, op, cDatum.interestVal)

    let (oracleValue, rDatum) =
      helpers.get_oracle_datum_value(outputs, op, cDatum.oracleVal)

    let exchangeRate = rDatum.exchange

    let utilisation = utilisationRatio(rDatum.borrowed, rDatum.supply)

    helpers.merkelTx(
      fn(collateral, loan) {
        let loanToken = assets.without_lovelace(loan.value)

        expect InlineDatum(datum) = collateral.datum
        expect colDatum: CollateralDatum = datum
        expect InlineDatum(datum) = loan.datum
        expect loanDatum: LoanDatum = datum

        let (lin, cin) =
          helpers.get_loan_col_in_datum(
            inputs,
            loanToken,
            cDatum.loanVal,
            cDatum.colVal,
          )

        let adaOut = assets.lovelace_of(collateral.value) + colDatum.yield
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
          cin.yield == colDatum.yield,
          oracleValue == expectedOracle,
          loanDatum.amount <= lin.amount,
          colDatum.amount == loanDatum.amount * 2,
          loanDatum.timestamp == rDatum.timestamp,
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
