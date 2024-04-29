// use aiken/dict
// use aiken/interval.{Interval, IntervalBound, NegativeInfinity, PositiveInfinity}
// use aiken/transaction.{Input, NoDatum, Output, Transaction, placeholder}
// use aiken/transaction/value
// use tests/tools.{
//   ScriptHash, collateralValHash, configMintHash, configValHash, loanMintHash,
//   loanValHash, makeAdaValue, makePolicyId, make_asset_name, oracleDatum,
//   oracleMintActionMint, oracleMintHash, oracleValHash, rewardsMintHash,
//   test_address, test_context, test_input, test_mint_purpose, test_oref,
//   test_output, test_script_address, test_signatories, test_spend_purpose,
//   test_tx_id,
// }

// //                        //
// // Validator Transactions //
// //                        //

// // pub fn configOutput() -> Output {
// //   let l =
// //     ScriptCredential(
// //       #"8efc8a322434c86df29198ab3f95e7627cf55363177fc3e37abba552",
// //     )
// //   let c =
// //     ScriptCredential(
// //       #"c87cb59525bbb34ecaa261fa002ef290748317e1cbb0300aeeec62d7",
// //     )
// //   let r =
// //     ScriptCredential(
// //       #"a3d0ea91754e4b26492533f94545a25e7e2d71af53058a166bc77786",
// //     )
// //   let datum = configDatum(l, c, r)
// //   let address = 
// //   let value = 
// // }

// pub fn test_oracle_mints_transaction() -> Transaction {
//   let tx =
//     Transaction {
//       inputs: [
//         test_input(
//           test_oref(#"cafe", 1),
//           test_output(test_address(#"face"), makeAdaValue(10), NoDatum),
//         ),
//       ],
//       reference_inputs: [],
//       outputs: [],
//       fee: value.zero(),
//       mint: value.to_minted_value(value.zero()),
//       certificates: [],
//       withdrawals: dict.new(),
//       validity_range: Interval {
//         lower_bound: IntervalBound {
//           bound_type: NegativeInfinity,
//           is_inclusive: True,
//         },
//         upper_bound: IntervalBound {
//           bound_type: PositiveInfinity,
//           is_inclusive: True,
//         },
//       },
//       extra_signatories: test_signatories(),
//       redeemers: dict.insert(
//         dict.new(),
//         key: "purpose",
//         value: test_mint_purpose(oracleMintHash),
//         oracleMintActionMint(),
//         compare,
//       ),
//       datums: dict.new(oracleMintHash, oracleDatum(1, 11111111, 15, 2)),
//       id: TransactionId { hash: #"" },
//     }
//   tx
// }

// //                 //
// // Validator UTxOs //
// //                 //

// // Oracle //

// pub fn oracleInput(
//   index: Int,
//   oracleScript: ScriptHash,
//   oracleMint: ByteArray,
// ) -> Input {
//   let txid = test_tx_id(#"")
//   let idx = index
//   let oref = test_oref(txid, idx)
//   let addr = test_script_address(oracleScript)
//   let value = test_value_with_token()
//   let out = test_output(addr, value, datum)
//   let input = test_input(oref, out)
// }

// pub fn oracleOutput() -> Output {
//   todo
// }

// pub fn oracleMintOutput() -> Output {
//   todo
// }

// pub fn configMintOutput() -> Output {
//   todo
// }

// pub fn configOutput() -> Output {
//   todo
// }

// pub fn configInput() -> Output {
//   todo
// }

// pub fn configRefInput() -> Input {
//   todo
// }

// pub fn rewardsOutput() -> Output {
//   todo
// }

// pub fn loanMintOutput() -> Output {
//   todo
// }

// pub fn loanValOutput() -> Output {
//   todo
// }

// pub fn loanValInput() -> Input {
//   todo
// }

// pub fn collateralOutput() -> Output {
//   todo
// }

// pub fn collateralInput() -> Output {
//   todo
// }
