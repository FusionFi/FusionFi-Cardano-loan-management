// use aiken/collection/list
// use aiken/collection/pairs
// use cardano/address.{Script}
// use cardano/assets.{PolicyId}
// use cardano/transaction.{InlineDatum, OutputReference, Transaction}
// use ccfl/types.{MerkelConfigDatum, YieldAction, YieldDatum}
//                   //
// Yield Vault Tests //
//                   //

// validator yieldVault(cp: PolicyId) {
//   spend(
//     _d: Option<YieldDatum>,
//     r: YieldAction,
//     _oref: OutputReference,
//     tx: Transaction,
//   ) {
//     let Transaction { reference_inputs, withdrawals, .. } = tx

//     expect Some(configIn) =
//       list.find(
//         reference_inputs,
//         fn(input) { list.has(assets.policies(input.output.value), cp) },
//       )

//     expect InlineDatum(datum) = configIn.output.datum
//     expect cDatum: MerkelConfigDatum = datum

//     expect Some(stakeVal) =
//       cDatum.collateralRedeemers
//         |> list.at(r.i)

//     pairs.has_key(withdrawals, Script(stakeVal))
//     // transaction includes withdrawalRedeemer and signed by withdrawalHash
//   }

//   else(_) {
//     fail
//   }
// }
