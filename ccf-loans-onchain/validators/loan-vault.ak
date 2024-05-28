use aiken/dict
use aiken/list
use aiken/transaction.{InlineDatum, ScriptContext, Transaction}
use aiken/transaction/credential.{Inline, ScriptCredential}
use aiken/transaction/value.{PolicyId}
use ccfl/types.{LoanDatum, MerkelConfigDatum, MerkelLoanAction}

validator(cp: PolicyId) {
  // this should be in the config datum instead
  fn mLoan(_d: LoanDatum, r: MerkelLoanAction, c: ScriptContext) {
    let ScriptContext { transaction, .. } = c
    let Transaction { reference_inputs, withdrawals, .. } = transaction

    expect Some(configIn) =
      list.find(
        reference_inputs,
        fn(input) { list.has(value.policies(input.output.value), cp) },
      )

    expect InlineDatum(datum) = configIn.output.datum
    expect cDatum: MerkelConfigDatum = datum

    expect Some(stakeVal) =
      cDatum.collateralRedeemers
        |> list.at(r.i)

    dict.has_key(withdrawals, Inline(ScriptCredential(stakeVal)))
  }
}
