use aiken/dict.{to_list}
use aiken/hash.{Blake2b_224, Hash}
use aiken/list.{any, filter, find, has, head}
use aiken/time.{PosixTime}
use aiken/transaction.{
  InlineDatum, Input, Mint, NoDatum, Output, OutputReference, ScriptContext,
  Spend, Transaction, find_input, find_script_outputs, placeholder,
}
use aiken/transaction/credential.{Script, ScriptCredential, VerificationKey}
use aiken/transaction/value.{
  PolicyId, flatten, from_minted_value, lovelace_of, policies, tokens,
  without_lovelace,
}
use tests/tools as t

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
