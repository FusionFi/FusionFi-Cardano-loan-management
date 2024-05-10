use aiken/hash.{Blake2b_224, Hash}
use aiken/list
use aiken/transaction.{
  Output, OutputReference, Redeemer, ScriptContext, Transaction, WithdrawFrom,
  find_input, find_script_outputs,
}
use aiken/transaction/credential.{
  Inline, Script, ScriptCredential, VerificationKey,
}

//         //
// Helpers //
//         //

pub fn get_own_singleton_output(
  tx: Transaction,
  oref: OutputReference,
) -> Output {
  expect Some(input) =
    tx.inputs
      |> find_input(oref)

  expect ScriptCredential(script_hash) = input.output.address.payment_credential
  let script_outputs =
    tx.outputs
      |> find_script_outputs(script_hash)

  expect list.length(script_outputs) == 1
  expect Some(output) =
    tx.outputs
      |> find_script_outputs(script_hash)
      |> list.head()
  output
}

pub fn withdraw0(
  withdrawal_logic: fn(Redeemer, Hash<Blake2b_224, Script>, Transaction) -> Bool,
  redeemer: Redeemer,
  ctx: ScriptContext,
) -> Bool {
  expect ScriptContext { transaction: tx, purpose: WithdrawFrom(stake_cred) } =
    ctx

  expect Inline(ScriptCredential(own_validator)) = stake_cred

  withdrawal_logic(redeemer, own_validator, tx)
}
