use aiken/dict
use aiken/list
use aiken/transaction.{InlineDatum, ScriptContext, Transaction}
use aiken/transaction/credential.{Inline, ScriptCredential}
use aiken/transaction/value.{PolicyId}
use ccfl/types.{CollateralDatum, MerkelCollateralAction, MerkelConfigDatum}

validator(cp: PolicyId) {
  fn mCol(_d: CollateralDatum, r: MerkelCollateralAction, c: ScriptContext) {
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
