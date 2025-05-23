use aiken/collection/list
use cardano/address.{Credential}
use cardano/assets.{PolicyId}
use cardano/transaction.{InlineDatum, Input, Output, Transaction}
use ccfl/helpers.{merkelTx}
use ccfl/types.{
  CollateralDatum, LoanDatum, MerkelConfigDatum, OracleDatum, WithdrawRedeemer,
}

//                              //
// Merkel Liquidation Validator //
//                              //

validator liquidate(p: PolicyId, cp: PolicyId) {
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

        let expectedOracle = assets.from_asset(p, lin.oracle, 1)

        let exchangeAdjustment = lin.amount * 1000
        let loanExpected = exchangeAdjustment / exchangeRate

        // let adaOut = value.lovelace_of(collateral.value) / 1000000
        let ratio = loanDatum.amount * 1000 / ( exchangeAdjustment / 100 )

        assets.lovelace_of(colIn.output.value) / 1000000 <= loanExpected * 85 / 100 && assets.without_lovelace(
          oracleOut.value,
        ) == expectedOracle && assets.lovelace_of(collateral.value) >= assets.lovelace_of(
          colIn.output.value,
        ) * ratio && colDatum.amount == loanDatum.amount * 2 && cin.yield == colDatum.yield
      },
      r.a,
      outputs,
    )
  }

  else(_) {
    fail
  }
}
