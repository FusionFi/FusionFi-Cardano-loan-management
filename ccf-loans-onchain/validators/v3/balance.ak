use cardano/address.{Credential}
use cardano/assets.{PolicyId}
use cardano/transaction.{InlineDatum, Output, Transaction}
use ccfl/helpersv3 as h
use ccfl/typesv3.{
  CollateralDatum, LoanDatum, MerkelConfigDatum, OracleDatum, WithdrawAction,
}

// staking validators that check the full transaction scope.

// Merkel Balance validates the whole transaction for the Balance redeemer case
// it combines both the merkel-loan && merkel-collateral cases together

validator balance(op: PolicyId, cp: PolicyId) {
  withdraw(r: WithdrawAction, _cred: Credential, tx: Transaction) {
    let cDatum: MerkelConfigDatum = h.get_config_datum(tx.reference_inputs, cp)

    let (oracleValue, rDatum) =
      h.get_oracle_datum_value(tx.outputs, op, cDatum.oracleVal)

    let exchangeRate = rDatum.exchange

    // For V3 we want to go by Policy not Hashes to save space on the configDatum.
    h.ioTx(
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

        let adaOut = assets.lovelace_of(outCol.value) / 1000000
        let exchangeAdjustment = loanDatum.amount * 1000
        let expectedCollateral = exchangeAdjustment / exchangeRate
        let minCollateralValue = expectedCollateral * 2
        let expectedOracle = assets.from_asset(op, loanDatum.oracle, 1)

        and {
          adaOut >= minCollateralValue,
          oracleValue == expectedOracle,
          loanDatum.amount == lin.amount,
        }
      },
    )
    // cin.yield == colDatum.yield,
  }

  else(_) {
    fail
  }
}
