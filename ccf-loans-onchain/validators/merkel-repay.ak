use aiken/dict
use aiken/list
use aiken/transaction.{
  InlineDatum, Input, Output, ScriptContext, Transaction, WithdrawFrom,
  placeholder,
}
use aiken/transaction/credential.{Inline, ScriptCredential}
use aiken/transaction/value.{PolicyId}
use ccfl/helpers.{merkelTx, withdraw4}
use ccfl/types.{
  CollateralDatum, LoanDatum, MerkelCollateralAction, MerkelConfigDatum,
  MerkelLoanAction, OracleDatum, ScriptHash, WithdrawRedeemer,
}
use tests/tools as t
use tests/transactions as tx

// staking validators that check the full transaction scope.

// Merkel Balance validates the whole transaction for the Balance redeemer case
// it combines both the merkel-loan && merkel-collateral cases together

validator(p: PolicyId, cp: PolicyId) {
  fn balance(r: WithdrawRedeemer, c: ScriptContext) {
    // True
    expect ScriptContext {
      transaction,
      purpose: WithdrawFrom(stake_credential),
    } = c

    let Transaction { inputs, outputs, reference_inputs, .. } = transaction

    expect Some(oracleOut) =
      list.find(
        outputs,
        fn(output) { list.has(value.policies(output.value), p) },
      )

    expect InlineDatum(datum) = oracleOut.datum
    expect rDatum: OracleDatum = datum

    let exchangeRate = rDatum.exchange

    expect Some(configIn) =
      list.find(
        reference_inputs,
        fn(input) { list.has(value.policies(input.output.value), cp) },
      )

    expect InlineDatum(datum) = configIn.output.datum
    expect cDatum: MerkelConfigDatum = datum

    merkelTx(
      fn(collateral, loan) {
        expect loanToken = value.without_lovelace(loan.value)
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

        let adaOut = value.lovelace_of(collateral.value) / 1000000
        let exchangeAdjustment = loanDatum.amount * 1000
        let expectedCollateral = exchangeAdjustment / exchangeRate
        let minCollateralValue = expectedCollateral * 2
        let expectedOracle = value.from_asset(p, loanDatum.oracle, 1)

        adaOut >= minCollateralValue && value.without_lovelace(oracleOut.value) == expectedOracle && loanDatum.amount <= lin.amount && colDatum.amount == loanDatum.amount * 2
      },
      r.a,
      outputs,
    )
  }
}
