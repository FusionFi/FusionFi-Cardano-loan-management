use aiken/hash.{Blake2b_224, Hash}
use aiken/list
// use aiken/string
use aiken/transaction.{
  Input, Output, OutputReference, Redeemer, ScriptContext, Transaction,
  WithdrawFrom, find_input, find_script_outputs,
}
use aiken/transaction/credential.{Address, Inline, Script, ScriptCredential}
use aiken/transaction/value
use ccfl/types.{ScriptHash}

//         //
// Helpers //
//         //

pub fn has_singleton_input(tx: Transaction, oref: OutputReference) -> Bool {
  expect Some(input) =
    tx.inputs
      |> find_input(oref)

  expect ScriptCredential(script_hash) = input.output.address.payment_credential

  list.length(
    list.filter(
      tx.inputs,
      fn(input) {
        input.output.address.payment_credential == ScriptCredential(script_hash)
      },
    ),
  ) == 1
}

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

pub fn withBurn(
  checkBurn: fn(Output) -> Bool,
  _loanVal: ScriptHash,
  redeemer: List<Int>,
  tx: Transaction,
) -> Bool {
  let Transaction { inputs, .. } = tx

  let txList =
    list.map(
      redeemer,
      fn(index) {
        let in = index
        expect Some(input) = list.at(inputs, in)
        input
      },
    )

  list.all(txList, fn(input) { checkBurn(input.output) })
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

pub fn merkel0(
  validation_logic: fn(Output, Output) -> Bool,
  redeemer: List<(Int, Int)>,
  _loanVal: ScriptHash,
  ctx: ScriptContext,
) -> Bool {
  let ScriptContext { transaction: tx, .. } = ctx

  let Transaction { inputs, outputs, .. } = tx

  expect [(in_ix, out_ix)] = redeemer

  expect Some(Input { output: in_utxo, output_reference: _in_ref }) =
    inputs |> list.at(in_ix)

  expect Some(out_utxo) = outputs |> list.at(out_ix)

  validation_logic(in_utxo, out_utxo)
}

pub fn merkelTx(
  validate: fn(Output, Output) -> Bool,
  redeemer: List<Int>,
  outputs: List<Output>,
) -> Bool {
  let txList =
    list.map(
      redeemer,
      fn(index) {
        let l = index
        expect Some(col) = list.at(outputs, l)
        expect Some(loan) =
          list.find(
            outputs,
            fn(output) {
              value.without_lovelace(output.value) == value.without_lovelace(
                col.value,
              ) && output.address.payment_credential != col.address.payment_credential
            },
          )
        (col, loan)
      },
    )

  list.all(
    txList,
    fn(pair) {
      let (col, loan) = pair
      validate(col, loan)
    },
  )
}

pub fn merkelBurn(
  validate: fn(Output, Output) -> Bool,
  redeemer: List<Int>,
  inputs: List<Input>,
) -> Bool {
  let txList =
    list.map(
      redeemer,
      fn(index) {
        let l = index
        expect Some(loan) = list.at(inputs, l)
        expect Some(col) =
          list.find(
            inputs,
            fn(input) {
              value.without_lovelace(input.output.value) == value.without_lovelace(
                loan.output.value,
              ) && input.output.address.payment_credential != loan.output.address.payment_credential
            },
          )
        (loan.output, col.output)
      },
    )

  list.all(
    txList,
    fn(pair) {
      let (loan, col) = pair
      validate(loan, col)
    },
  )
}

pub fn merkelYield(
  outputs: List<Output>,
  redeemer: List<Int>,
  validate: fn(Output) -> Bool,
) -> Bool {
  let filtered =
    list.map(
      redeemer,
      fn(index) {
        expect Some(out) = list.at(outputs, index)
        out
      },
    )

  list.all(filtered, fn(output) { validate(output) })
}
