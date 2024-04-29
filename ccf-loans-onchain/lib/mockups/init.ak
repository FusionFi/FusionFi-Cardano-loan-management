// use aiken/dict.{to_list, values}
// use aiken/hash.{Blake2b_224, Hash}
// use aiken/list.{any, filter, find, has, head}
// use aiken/time.{PosixTime}
// use aiken/transaction.{
//   InlineDatum, Input, Mint, Output, OutputReference, ScriptContext, Spend,
//   Transaction, find_input, find_script_outputs,
// }
// use aiken/transaction/credential.{ScriptCredential, VerificationKey}
// use aiken/transaction/value.{
//   PolicyId, from_minted_value, lovelace_of, policies, quantity_of, tokens,
//   without_lovelace,
// }

// //            //
// // Data Types //
// //            //

// type VerificationKeyHash =
//   Hash<Blake2b_224, VerificationKey>

// type MintAction {
//   AMint { loanCurrency: ByteArray, loanValue: Int, timestamp: PosixTime }
//   ABurn
// }

// type OMintAction {
//   OMint
//   OBurn
// }

// type OracleAction {
//   Update
//   Close
// }

// type OracleDatum {
//   usdAda: Int,
//   timestamp: PosixTime,
// }

// type LoanAction {
//   a: Int,
//   // 1 2 3
//   b: PosixTime,
//   c: Int,
// }

// type LoanDatum {
//   collateral: ByteArray,
//   // asset As String e.g. "ADA"
//   collateralValue: Int,
//   // expected Collateral Value min
//   loanCurrency: ByteArray,
//   // e.g. "USD"
//   loanValue: Int,
//   timestamp: PosixTime,
// }

// //           //
// // Loan Mint //
// //           //

// validator(o: PolicyId) {
//   fn loanMint(r: MintAction, c: ScriptContext) -> Bool {
//     let ScriptContext { transaction, purpose } = c
//     expect Mint(policyId) = purpose

//     let Transaction { mint, outputs, reference_inputs, .. } = transaction

//     expect [(tName, tAmt)] =
//       mint
//         |> value.from_minted_value()
//         |> value.tokens(policyId)
//         |> dict.to_list()

//     when r is {
//       AMint { loanCurrency, loanValue, timestamp } -> {
//         expect Some(refIn) =
//           head(
//             filter(
//               reference_inputs,
//               fn(ref) { has(policies(ref.output.value), o) },
//             ),
//           )
//         expect InlineDatum(datum) = refIn.output.datum
//         expect rDatum: OracleDatum = datum
//         let exchangeRate = rDatum.usdAda

//         any(
//           outputs,
//           fn(output) {
//             expect has(policies(output.value), policyId)
//             expect InlineDatum(datum) = output.datum
//             expect datum: LoanDatum = datum

//             datum.loanCurrency == loanCurrency && datum.timestamp == timestamp && datum.collateralValue == datum.loanValue * 2 && lovelace_of(
//               output.value,
//             ) >= datum.collateralValue * exchangeRate * 1000000
//           },
//         )
//       }

//       ABurn -> True
//     }
//   }
// }

// //            //
// // Loan Vault //
// //            //

// validator(p: PolicyId, o: PolicyId) {
//   fn loanVault(d: LoanDatum, r: LoanAction, c: ScriptContext) -> Bool {
//     let ScriptContext { transaction, purpose } = c
//     expect Spend(oref) = purpose

//     let Transaction { inputs, outputs, reference_inputs, .. } = transaction

//     expect Some(refIn) =
//       find(reference_inputs, fn(input) { has(policies(input.output.value), o) })

//     expect InlineDatum(datum) = refIn.output.datum
//     expect rDatum: OracleDatum = datum
//     let exchangeRate = rDatum.usdAda

//     when r.a is {
//       1 -> {
//         // balance
//         let ownOut = get_own_singleton_output(transaction, oref)
//         let adaOut = lovelace_of(ownOut.value) / 1000000
//         let newCollateralValue = adaOut / exchangeRate
//         let minCollateralValue = d.loanValue * exchangeRate * ( 50 / 100 )
//         expect has(policies(ownOut.value), p)
//         expect InlineDatum(datum) = ownOut.datum
//         expect datum: LoanDatum = datum

//         datum.collateral == d.collateral && datum.collateralValue == newCollateralValue && datum.loanCurrency == d.loanCurrency && datum.loanValue == d.loanValue && datum.timestamp == r.b && adaOut >= minCollateralValue
//       }

//       2 -> {
//         // liquidate
//         let ownOut = get_own_singleton_output(transaction, oref)
//         let adaOut = lovelace_of(ownOut.value) / 1000000
//         let newCollateralValue = adaOut / exchangeRate
//         expect has(policies(ownOut.value), p)
//         expect InlineDatum(datum) = ownOut.datum
//         expect datum: LoanDatum = datum
//         let minCollateralValue = datum.loanValue * exchangeRate * ( 85 / 100 )

//         datum.collateral == d.collateral && datum.collateralValue == newCollateralValue && datum.loanCurrency == d.loanCurrency && datum.loanValue == d.loanValue - r.c && datum.timestamp == r.b && adaOut >= minCollateralValue
//       }
//       // close
//       _ -> d.loanValue == 0
//     }
//   }
// }

// //              //
// // Price Oracle //
// //              //

// validator(o: VerificationKeyHash, p: PolicyId) {
//   fn oracleVault(d: OracleDatum, r: OracleAction, c: ScriptContext) -> Bool {
//     let ScriptContext { transaction, purpose } = c
//     expect Spend(ownRef) = purpose

//     when r is {
//       Update -> {
//         let out = get_own_singleton_output(transaction, ownRef)
//         expect [(_, 1)] =
//           without_lovelace(out.value)
//             |> tokens(p)
//             |> to_list()
//         expect InlineDatum(datum) = out.datum
//         expect datum: OracleDatum = datum

//         has(transaction.extra_signatories, o)
//       }
//       Close -> {
//         expect Some(input) = find_input(transaction.inputs, ownRef)

//         expect [(oName, 1)] =
//           // get singleton name
//           without_lovelace(input.output.value)
//             |> tokens(p)
//             |> to_list()

//         expect [(oName, -1)] =
//           transaction.mint
//             |> value.from_minted_value()
//             |> value.tokens(p)
//             |> dict.to_list()

//         has(transaction.extra_signatories, o)
//       }
//     }
//   }
// }

// //             //
// // Oracle Mint //
// //             //

// validator(o: VerificationKeyHash) {
//   fn oracleMint(r: OMintAction, c: ScriptContext) -> Bool {
//     let ScriptContext { transaction, purpose } = c
//     expect Mint(policyId) = purpose

//     expect [(oName, oAmt)] =
//       transaction.mint
//         |> from_minted_value()
//         |> tokens(policyId)
//         |> to_list()

//     when r is {
//       OMint -> list.has(transaction.extra_signatories, o) && oAmt == 1
//       OBurn -> list.has(transaction.extra_signatories, o) && oAmt == -1
//     }
//   }
// }

// //         //
// // Helpers //
// //         //

// fn get_own_singleton_output(tx: Transaction, oref: OutputReference) -> Output {
//   expect Some(input) =
//     tx.inputs
//       |> find_input(oref)

//   expect ScriptCredential(script_hash) = input.output.address.payment_credential
//   let script_outputs =
//     tx.outputs
//       |> find_script_outputs(script_hash)

//   expect list.length(script_outputs) == 1
//   expect Some(output) =
//     tx.outputs
//       |> find_script_outputs(script_hash)
//       |> list.head()
//   output
// }
