use aiken/collection/list
use cardano/address.{Credential}
use cardano/assets.{PolicyId}
use cardano/transaction.{InlineDatum, Input, Output, Transaction}
use ccfl/helpers.{merkelTx}
use ccfl/types.{
  CollateralDatum, LoanDatum, MerkelConfigDatum, OracleDatum, WithdrawRedeemer,
}

// staking validators that check the full transaction scope.

// Merkel Balance validates the whole transaction for the Balance redeemer case
// it combines both the merkel-loan && merkel-collateral cases together

validator balance(p: PolicyId, cp: PolicyId) {
  withdraw(r: WithdrawRedeemer, _cred: Credential, tx: Transaction) {
    let Transaction { inputs, outputs, reference_inputs, .. } = tx

    expect Some(oracleOut) =
      list.find(
        outputs,
        fn(output) { list.has(assets.policies(output.value), p) },
      )

    expect InlineDatum(datum) = oracleOut.datum
    expect rDatum: OracleDatum = datum

    let exchangeRate = rDatum.exchange

    expect Some(configIn) =
      list.find(
        reference_inputs,
        fn(input) { list.has(assets.policies(input.output.value), cp) },
      )

    expect InlineDatum(datum) = configIn.output.datum
    expect _cDatum: MerkelConfigDatum = datum

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

        let adaOut =
          ( assets.lovelace_of(collateral.value) + colDatum.yield ) / 1000000
        let exchangeAdjustment = loanDatum.amount * 1000
        let expectedCollateral = exchangeAdjustment / exchangeRate
        let minCollateralValue = expectedCollateral * 2
        let expectedOracle = assets.from_asset(p, loanDatum.oracle, 1)

        adaOut >= minCollateralValue && assets.without_lovelace(oracleOut.value) == expectedOracle && loanDatum.amount == lin.amount && cin.yield == colDatum.yield
      },
      r.a,
      outputs,
    )
  }

  else(_) {
    fail
  }
}
