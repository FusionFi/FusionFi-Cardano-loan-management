use cardano/address.{Credential}
use cardano/assets.{PolicyId}
use cardano/transaction.{InlineDatum, Output, Transaction}
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

    let (oracleValue, rDatum) =
      helpers.get_oracle_datum_value(tx.outputs, p, cDatum.oracleVal)

    let exchangeRate = rDatum.exchange

    helpers.ioTx(
      r.a,
      cDatum.colVal,
      cDatum.loanVal,
      tx.inputs,
      tx.outputs,
      fn(inCol, inLoan, outCol, outLoan) {
        // let loanToken = assets.without_lovelace(outLoan.value)
        expect InlineDatum(datum1) = outCol.datum
        expect colDatum: CollateralDatum = datum1
        expect InlineDatum(datum2) = outLoan.datum
        expect loanDatum: LoanDatum = datum2
        expect InlineDatum(datum3) = inCol.output.datum
        expect cin: CollateralDatum = datum3
        expect InlineDatum(datum4) = inLoan.output.datum
        expect lin: LoanDatum = datum4

        let adaOut =
          ( assets.lovelace_of(outCol.value) + colDatum.yield ) / 1000000
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
    )
  }

  else(_) {
    fail
  }
}
