use cardano/address.{Credential}
use cardano/assets.{PolicyId}
use cardano/transaction.{InlineDatum, Output, Transaction}
use ccfl/helpers
use ccfl/helpersv3 as h
use ccfl/typesv3.{
  CollateralDatum, LoanDatum, MerkelConfigDatum, OracleDatum, WithdrawAction,
}

//                              //
// Merkel Liquidation Validator //
//                              //

validator liquidate(op: PolicyId, cp: PolicyId) {
  withdraw(r: WithdrawAction, _cred: Credential, tx: Transaction) {
    let cDatum: MerkelConfigDatum = h.get_config_datum(tx.reference_inputs, cp)

    let (oracleValue, rDatum) =
      h.get_oracle_datum_value(tx.outputs, op, cDatum.oracleVal)

    let exchangeRate = rDatum.exchange

    helpers.merkelTx(
      fn(collateral, loan) {
        let loanToken = assets.without_lovelace(loan.value)
        expect InlineDatum(datum) = collateral.datum
        expect colDatum: CollateralDatum = datum
        expect InlineDatum(datum) = loan.datum
        expect loanDatum: LoanDatum = datum

        let (_linValue, lin, cinValue, cin) =
          helpers.get_loan_col_in(
            tx.inputs,
            loanToken,
            cDatum.loanVal,
            cDatum.colVal,
          )

        let expectedOracle = assets.from_asset(op, lin.oracle, 1)

        let exchangeAdjustment = lin.amount * 1000
        let loanExpected = exchangeAdjustment / exchangeRate

        // let adaOut = value.lovelace_of(collateral.value) / 1000000
        let ratio = loanDatum.amount * 1000 / ( exchangeAdjustment / 100 )

        and {
          (assets.lovelace_of(cinValue) / 1000000 <= loanExpected * 85 / 100)?,
          (assets.without_lovelace(oracleValue) == expectedOracle)?,
          (assets.lovelace_of(collateral.value) >= assets.lovelace_of(cinValue) * ratio)?,
          (colDatum.amount == loanDatum.amount * 2)?,
        }
      },
      r.a,
      tx.outputs,
    )
  }

  else(_) {
    fail
  }
}
