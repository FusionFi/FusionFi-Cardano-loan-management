use aiken/collection/list
use cardano/address.{Credential}
use cardano/assets.{PolicyId}
use cardano/transaction.{InlineDatum, Input, Output, Transaction}
use ccfl/helpers
use ccfl/types.{
  CollateralDatum, LoanDatum, MerkelConfigDatum, OracleDatum, WithdrawRedeemer,
}

// staking validators that check the full transaction scope.

// Merkel Balance validates the whole transaction for the Balance redeemer case
// it combines both the merkel-loan && merkel-collateral cases together

validator balance(p: PolicyId, cp: PolicyId) {
  withdraw(r: WithdrawRedeemer, _cred: Credential, tx: Transaction) {
    let cDatum: MerkelConfigDatum =
      helpers.get_config_datum(tx.reference_inputs, cp)

    let Pair(oracleValue, rDatum) =
      helpers.get_oracle_datum_value(tx.outputs, p, cDatum.oracleVal)

    let exchangeRate = rDatum.exchange

    helpers.merkelTx(
      fn(collateral, loan) {
        let loanToken = assets.without_lovelace(loan.value)
        expect InlineDatum(datum) = collateral.datum
        expect colDatum: CollateralDatum = datum
        expect InlineDatum(datum) = loan.datum
        expect loanDatum: LoanDatum = datum

        let Pair(lin, cin) =
          helpers.get_loan_col_in_datum(
            tx.inputs,
            loanToken,
            cDatum.loanVal,
            cDatum.colVal,
          )

        let adaOut =
          ( assets.lovelace_of(collateral.value) + colDatum.yield ) / 1000000
        let exchangeAdjustment = loanDatum.amount * 1000
        let expectedCollateral = exchangeAdjustment / exchangeRate
        let minCollateralValue = expectedCollateral * 2
        let expectedOracle = assets.from_asset(p, loanDatum.oracle, 1)

        and {
          adaOut >= minCollateralValue,
          oracleValue == expectedOracle,
          loanDatum.amount == lin.amount,
          cin.yield == colDatum.yield,
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
