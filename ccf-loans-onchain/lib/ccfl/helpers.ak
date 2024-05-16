use aiken/dict
use aiken/hash.{Blake2b_224, Hash}
use aiken/list
// use aiken/string
use aiken/transaction.{
  Input, Output, OutputReference, Redeemer, ScriptContext, Transaction,
  WithdrawFrom, find_input, find_script_outputs,
}
use aiken/transaction/credential.{Address, Inline, Script, ScriptCredential}
use ccfl/types.{LoanAction, ScriptHash}

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
  loanVal: ScriptHash,
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

pub fn withdraw1(
  validation_logic: fn(Output, Output, LoanAction) -> Bool,
  redeemer: List<(Int, Int, Int)>,
  ctx: ScriptContext,
) -> Bool {
  withdraw0(
    fn(indicesData, own_validator, tx) {
      let Transaction { inputs, outputs, redeemers, .. } = tx
      let (script_inputs, script_input_count) =
        list.foldr(
          inputs,
          ([], 0),
          fn(i, acc_tuple) {
            expect Input {
              output: Output {
                address: Address {
                  payment_credential: ScriptCredential(script),
                  ..
                },
                ..
              } as o,
              ..
            } = i
            if script == own_validator {
              let (acc, count) = acc_tuple
              ([o, ..acc], count + 1)
            } else {
              acc_tuple
            }
          },
        )

      expect indices: List<(Int, Int, Int)> = indicesData
      let (_, _, _, input_index_count) =
        list.foldl(
          indices,
          (-1, -1, -1, 0),
          fn(curr, acc) {
            let (in0, out0, red0, count) = acc
            let (in1, out1, red1) = curr
            if in1 > in0 && out1 > out0 && red1 > red0 {
              expect Some(in_utxo) = script_inputs |> list.at(in1)
              expect Some(out_utxo) = outputs |> list.at(out1)
              expect Some((_purpose, rdmr)) =
                redeemers |> dict.to_list |> list.at(red1)
              expect red: LoanAction = rdmr
              if validation_logic(in_utxo, out_utxo, red) {
                (in1, out1, red1, count + 1)
              } else {
                fail @"Validation failed"
              }
            } else {
              // Input and output indices must be ordered to disallow
              // duplicates.
              fail @"Input and output indices must be in ascending orders"
            }
          },
        )
      (script_input_count == input_index_count)?
    },
    redeemer,
    ctx,
  )
}

// pub fn withdraw2(
//   validation_logic: fn(Output, Output) -> Bool,
//   redeemer: List<(Int, Int)>,
//   loanVal: ScriptHash,
//   ctx: ScriptContext,
// ) -> Bool {
//   let Transaction { inputs, outputs, .. } = ctx.transaction

// let (script_inputs, script_input_count) =
//   list.foldr(
//     inputs,
//     ([], 0),
//     fn(i, acc_tuple) {
//       expect Input {
//         output: Output {
//           address: Address {
//             payment_credential: ScriptCredential(script),
//             ..
//           },
//           ..
//         } as o,
//         ..
//       } = i
//       if script == loanVal {
//         let (acc, count) = acc_tuple
//         ([o, ..acc], count + 1)
//       } else {
//         acc_tuple
//       }
//     },
//   )
// trace string.from_int(script_input_count)
//   let (script_inputs, script_input_count) =
//     list.foldr(
//       inputs,
//       ([], 0),
//       fn(input, acc_tuple)
//     )

//   expect indices: List<(Int, Int)> = redeemer
//   let (_, _, input_index_count) =
//     list.foldl(
//       indices,
//       (-1, -1, 0),
//       fn(curr, acc) {
//         let (in0, out0, count) = acc
//         let (in1, out1) = curr
//         if in1 > in0 && out1 > out0 {
//           expect Some(in_utxo) = script_inputs |> list.at(in1)
//           expect Some(out_utxo) = outputs |> list.at(out1)
//           if validation_logic(in_utxo, out_utxo) {
//             (in1, out1, count + 1)
//           } else {
//             fail @"Validation failed"
//           }
//         } else {
//           // Input and output indices must be ordered to disallow
//           // duplicates.
//           fail @"Input and output indices must be in ascending orders"
//         }
//       },
//     )
//   (script_input_count == input_index_count)?
// }

pub fn withdraw3(
  input_validator: fn(Input) -> Bool,
  input_output_validator: fn(Output, Output) -> Bool,
  collective_output_validator: fn(List<Output>, Int) -> Bool,
  redeemer: List<(Int, List<Int>)>,
  ctx: ScriptContext,
) -> Bool {
  withdraw0(
    fn(indicesData, own_validator, tx) {
      let Transaction { inputs, outputs, .. } = tx
      let (script_inputs, script_input_count) =
        list.foldr(
          inputs,
          ([], 0),
          fn(i, acc_tuple) {
            expect Input {
              output: Output {
                address: Address {
                  payment_credential: ScriptCredential(script),
                  ..
                },
                ..
              },
              ..
            } = i
            if script == own_validator {
              let (acc, count) = acc_tuple
              ([i, ..acc], count + 1)
            } else {
              acc_tuple
            }
          },
        )
      expect indices: List<(Int, List<Int>)> = indicesData
      // Folding the outer list of indices from left.
      let (_, _, input_index_count) =
        list.foldl(
          indices,
          (-1, -1, 0),
          fn(curr, prev_ixs_and_count) {
            let (prev_in_ix, latest_out_ix, input_count_so_far) =
              prev_ixs_and_count

            let (curr_in_ix, out_ixs) = curr

            expect Some(Input { output: in_utxo, .. } as input) =
              script_inputs |> list.at(curr_in_ix)

            expect input_validator(input)?

            if curr_in_ix > prev_in_ix {
              // Folding the inner list of output indices from left. Since
              // found UTxOs are going to be added to the head of the
              // accumulator while the folding occurs from left, in order to
              // provide a more intuitive interface, the UTxOs list need to be
              // reversed before `validation_logic` is applied to it.
              let (new_latest_out_ix, out_utxos_reversed, output_count) =
                list.foldl(
                  out_ixs,
                  (latest_out_ix, [], 0),
                  fn(curr_out_ix, acc_triplet) {
                    let (prev_out_ix, utxos_so_far, count) = acc_triplet
                    if curr_out_ix > prev_out_ix {
                      expect Some(out_utxo) = outputs |> list.at(curr_out_ix)
                      expect input_output_validator(in_utxo, out_utxo)?
                      (
                        curr_out_ix,
                        utxos_so_far |> list.push(out_utxo),
                        count + 1,
                      )
                    } else {
                      fail @"All output indices must be in ascending order"
                    }
                  },
                )
              let out_utxos = list.reverse(out_utxos_reversed)
              if collective_output_validator(out_utxos, output_count) {
                // Passing the current input index, and the biggest output
                // index found with the inner fold.
                (curr_in_ix, new_latest_out_ix, input_count_so_far + 1)
              } else {
                fail @"Collection of outputs are not valid"
              }
            } else {
              fail @"Input indices must be in ascending order"
            }
          },
        )
      (script_input_count == input_index_count)?
    },
    redeemer,
    ctx,
  )
}

pub fn withdraw4(
  validation_logic: fn(Output, Output) -> Bool,
  loanVal: ScriptHash,
  redeemer: List<(Int, Int)>,
  tx: Transaction,
) -> Bool {
  let Transaction { inputs, outputs, .. } = tx

  let txList =
    list.map(
      redeemer,
      fn(index) {
        expect (in, out) = index
        expect Some(input) = list.at(inputs, in)
        expect Some(output) = list.at(outputs, out)
        (input, output)
      },
    )

  list.all(
    txList,
    fn(io) {
      expect (input, output) = io
      validation_logic(input.output, output)
    },
  )
}
