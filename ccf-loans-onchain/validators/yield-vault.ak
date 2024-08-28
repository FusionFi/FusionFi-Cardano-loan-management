use aiken/list
use aiken/pairs
use aiken/transaction.{InlineDatum, ScriptContext, Spend, Transaction}
use aiken/transaction/credential.{Inline, ScriptCredential}
use aiken/transaction/value.{PolicyId}
use ccfl/types.{MerkelConfigDatum, YieldAction, YieldDatum}

validator(cp: PolicyId) {
  fn yieldVault(_d: YieldDatum, r: YieldAction, c: ScriptContext) {
    let ScriptContext { transaction, purpose } = c
    expect Spend(_oref) = purpose

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

    pairs.has_key(withdrawals, Inline(ScriptCredential(stakeVal)))
    // transaction includes withdrawalRedeemer and signed by withdrawalHash
  }
}
