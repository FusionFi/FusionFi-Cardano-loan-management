// use aiken/dict.{to_list, values}
// use aiken/hash.{Blake2b_224, Hash}
// use aiken/list.{any, filter, find, has, head}
// use aiken/time.{PosixTime}
// use aiken/transaction.{
//   InlineDatum, Input, Mint, Output, OutputReference, ScriptContext, Spend,
//   Transaction, find_input, find_script_outputs,
// }
// use aiken/transaction/credential.{Script, ScriptCredential, VerificationKey}
// use aiken/transaction/value.{
//   PolicyId, flatten, from_minted_value, lovelace_of, policies, quantity_of,
//   tokens, without_lovelace,
// }

// // Separate Collateral & LoanData //

// // These contracts split collateral from Loan data with a token pair
// // We will actually need a reference input to differenciate the recieve validators
// // So I have added a Config ref input which has these validator hashes to check against
// // credentials

// //            //
// // Data Types //
// //            //

// type VerificationKeyHash =
//   Hash<Blake2b_224, VerificationKey>

// type ScriptHash =
//   Hash<Blake2b_224, Script>

// type SConfigDatum {
//   loanVal: ScriptHash,
//   colVal: ScriptHash,
// }

// type SConfigAction {
//   ConUpdate { loanVal: ScriptHash, colVal: ScriptHash }
//   ConClose
// }

// type SLoanAction {
//   SLBalance
//   SLLiquidate
//   SLClose
// }

// type SLoanDatum {
//   amount: Int,
//   interest: Int,
//   term: Int,
//   status: ByteArray,
// }

// type SColAction {
//   SCBalance
//   SCLiquidate
//   SCClose
// }

// type SColDatum {
//   amount: Int,
//   status: ByteArray,
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

// //                    //
// // Separate Loan Mint //
// //                    //

// // Mints 2 tokens 
// // sends one to loan vault with datum
// // sends one to collateral vault with datum

// validator(op: PolicyId, cp: PolicyId) {
//   fn sLoanMint(r: MintAction, c: ScriptContext) -> Bool {
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
//         expect Some(oracleIn) =
//           head(
//             filter(
//               reference_inputs,
//               fn(ref) { has(policies(ref.output.value), op) },
//             ),
//           )
//         expect InlineDatum(datum) = oracleIn.output.datum
//         expect rDatum: OracleDatum = datum
//         let exchangeRate = rDatum.usdAda

//         expect Some(configIn) =
//           head(
//             filter(
//               reference_inputs,
//               fn(ref) { has(policies(ref.output.value), cp) },
//             ),
//           )
//         expect InlineDatum(datum) = configIn.output.datum
//         expect cDatum: SConfigDatum = datum

//         expect Some(loanOut) =
//           find(
//             outputs,
//             fn(output) {
//               output.address.payment_credential == ScriptCredential(
//                 cDatum.loanVal,
//               ) && has(policies(output.value), policyId)
//             },
//           )
//         expect Some(colOut) =
//           find(
//             outputs,
//             fn(output) {
//               output.address.payment_credential == ScriptCredential(
//                 cDatum.colVal,
//               ) && has(policies(output.value), policyId)
//             },
//           )
//         expect InlineDatum(datum) = loanOut.datum
//         expect lDatum: SLoanDatum = datum
//         expect InlineDatum(datum) = colOut.datum
//         expect cDatum: SColDatum = datum
//         lDatum.amount == loanValue && lDatum.interest == 15 && lDatum.term == 0 && lDatum.status == "Active" && cDatum.amount == loanValue * 2 && cDatum.status == "Active" && lovelace_of(
//           colOut.value,
//         ) >= lDatum.amount * exchangeRate * 1000000 && tAmt == 2
//       }

//       ABurn -> True
//     }
//   }
// }

// //                     //
// // Separate Loan Vault //
// //                     //

// validator(op: PolicyId, lp: PolicyId) {
//   fn sLoanVal(d: SLoanDatum, r: SLoanAction, c: ScriptContext) -> Bool {
//     let ScriptContext { transaction, purpose } = c
//     expect Spend(oref) = purpose

//     let Transaction { inputs, outputs, reference_inputs, .. } = transaction

//     expect Some(oracleIn) =
//       find(
//         reference_inputs,
//         fn(input) { has(policies(input.output.value), op) },
//       )
//     expect InlineDatum(datum) = oracleIn.output.datum
//     expect rDatum: OracleDatum = datum
//     let exchangeRate = rDatum.usdAda

//     expect Some(configIn) =
//       find(
//         reference_inputs,
//         fn(input) { has(policies(input.output.value), lp) },
//       )
//     expect InlineDatum(datum) = configIn.output.datum
//     expect cDatum: SConfigDatum = datum

//     when r is {
//       SLBalance -> {
//         expect Some(ownIn) = find_input(inputs, oref)

//         expect Some(loanToken) =
//           head(flatten(without_lovelace(ownIn.output.value)))

//         expect Some(colOut) =
//           find(
//             outputs,
//             fn(output) {
//               expect Some(colToken) =
//                 head(flatten(without_lovelace(output.value)))
//               output.address.payment_credential == ScriptCredential(
//                 cDatum.colVal,
//               ) && loanToken == colToken
//             },
//           )
//         expect InlineDatum(datum) = colOut.datum
//         expect cDatum: SColDatum = datum

//         let ownOut = get_own_singleton_output(transaction, oref)
//         let adaOut = lovelace_of(colOut.value) / 1000000
//         let newCollateralValue = adaOut / exchangeRate
//         let minCollateralValue = d.amount * exchangeRate * ( 50 / 100 )
//         expect has(policies(ownOut.value), lp)
//         expect InlineDatum(datum) = ownOut.datum
//         expect datum: SLoanDatum = datum

//         datum.amount == d.amount && datum.interest == d.interest && datum.term == d.term && datum.status == d.status && adaOut >= minCollateralValue
//       }

//       SLLiquidate -> {
//         expect Some(ownIn) = find_input(inputs, oref)
//         expect Some(loanToken) =
//           head(flatten(without_lovelace(ownIn.output.value)))

//         expect Some(colOut) =
//           find(
//             outputs,
//             fn(output) {
//               expect Some(colToken) =
//                 head(flatten(without_lovelace(output.value)))
//               output.address.payment_credential == ScriptCredential(
//                 cDatum.colVal,
//               ) && loanToken == colToken
//             },
//           )
//         expect InlineDatum(datum) = colOut.datum
//         expect cDatum: SColDatum = datum

//         let ownOut = get_own_singleton_output(transaction, oref)
//         let adaOut = lovelace_of(colOut.value) / 1000000
//         let newCollateralValue = adaOut / exchangeRate
//         expect has(policies(ownOut.value), lp)
//         expect InlineDatum(datum) = ownOut.datum
//         expect datum: SLoanDatum = datum
//         let minCollateralValue = datum.amount * exchangeRate * ( 85 / 100 )

//         datum.amount == d.amount && datum.interest == d.interest && datum.term == d.term && datum.status == d.status && adaOut >= minCollateralValue
//       }
//       // close
//       SLClose -> d.amount == 0
//     }
//   }
// }

// //                           //
// // Separate Collateral Vault //
// //                           //

// validator(op: PolicyId, lp: PolicyId) {
//   fn cVal(d: SColDatum, r: SColAction, c: ScriptContext) -> Bool {
//     let ScriptContext { transaction, purpose } = c
//     expect Spend(oref) = purpose

//     let Transaction { inputs, outputs, reference_inputs, .. } = transaction

//     expect Some(oracleIn) =
//       find(
//         reference_inputs,
//         fn(input) { has(policies(input.output.value), op) },
//       )
//     expect InlineDatum(datum) = oracleIn.output.datum
//     expect rDatum: OracleDatum = datum
//     let exchangeRate = rDatum.usdAda

//     expect Some(configIn) =
//       find(
//         reference_inputs,
//         fn(input) { has(policies(input.output.value), lp) },
//       )
//     expect InlineDatum(datum) = configIn.output.datum
//     expect cDatum: SConfigDatum = datum

//     when r is {
//       SCBalance -> {
//         expect Some(ownIn) = find_input(inputs, oref)

//         expect Some(collateralToken) =
//           head(flatten(without_lovelace(ownIn.output.value)))

//         expect Some(loanOut) =
//           find(
//             outputs,
//             fn(output) {
//               expect Some(loanToken) =
//                 head(flatten(without_lovelace(output.value)))
//               output.address.payment_credential == ScriptCredential(
//                 cDatum.loanVal,
//               ) && loanToken == collateralToken
//             },
//           )
//         expect InlineDatum(datum) = loanOut.datum
//         expect lDatum: SLoanDatum = datum

//         let ownOut = get_own_singleton_output(transaction, oref)
//         expect InlineDatum(datum) = ownOut.datum
//         expect outDatum: SColDatum = datum

//         lovelace_of(ownOut.value) >= lDatum.amount * exchangeRate * ( 50 / 100 ) * 1000000 && outDatum.amount == lovelace_of(
//           ownOut.value,
//         ) / exchangeRate / 1000000 && has(
//           flatten(ownOut.value),
//           collateralToken,
//         )
//       }
//       // && outDatum.timestamp == timestamp
//       SCLiquidate -> {
//         expect Some(ownIn) = find_input(inputs, oref)

//         expect Some(collateralToken) =
//           head(flatten(without_lovelace(ownIn.output.value)))

//         expect Some(loanOut) =
//           find(
//             outputs,
//             fn(output) {
//               expect Some(loanToken) =
//                 head(flatten(without_lovelace(output.value)))
//               output.address.payment_credential == ScriptCredential(
//                 cDatum.loanVal,
//               ) && loanToken == collateralToken
//             },
//           )
//         expect InlineDatum(datum) = loanOut.datum
//         expect lDatum: SLoanDatum = datum

//         let ownOut = get_own_singleton_output(transaction, oref)
//         expect InlineDatum(datum) = ownOut.datum
//         expect outDatum: SColDatum = datum

//         lovelace_of(ownOut.value) >= lDatum.amount * exchangeRate * ( 50 / 100 ) * 1000000 && outDatum.amount == lovelace_of(
//           ownOut.value,
//         ) / exchangeRate / 1000000 && has(
//           flatten(ownOut.value),
//           collateralToken,
//         )
//       }

//       // && outDatum.timestamp == timestamp
//       SCClose -> True
//     }
//   }
// }

// //                  //
// // Config Validator //
// //                  //

// validator(o: VerificationKeyHash, cp: PolicyId) {
//   fn configValidator(
//     d: SConfigDatum,
//     r: SConfigAction,
//     c: ScriptContext,
//   ) -> Bool {
//     let ScriptContext { transaction, purpose } = c
//     expect Spend(oref) = purpose

//     let Transaction { inputs, outputs, extra_signatories, .. } = transaction

//     when r is {
//       ConUpdate { loanVal, colVal } -> {
//         let ownOut = get_own_singleton_output(transaction, oref)
//         expect InlineDatum(datum) = ownOut.datum
//         expect outDatum: SConfigDatum = datum

//         has(extra_signatories, o) && has(policies(ownOut.value), cp) && outDatum.loanVal == loanVal && outDatum.colVal == colVal
//       }

//       ConClose -> has(extra_signatories, o)
//     }
//   }
// }

// //                       //
// // Config Minting Policy //
// //                       //

// validator(o: VerificationKeyHash) {
//   fn configMint(r: SConfigAction, c: ScriptContext) -> Bool {
//     let ScriptContext { transaction, purpose } = c
//     expect Mint(policyId) = purpose

//     let Transaction { outputs, extra_signatories, mint, .. } = transaction

//     expect [(tName, tAmt)] =
//       mint
//         |> value.from_minted_value()
//         |> value.tokens(policyId)
//         |> dict.to_list()

//     when r is {
//       ConUpdate { loanVal, colVal } -> {
//         expect Some(ownOut) =
//           find(outputs, fn(output) { has(policies(output.value), policyId) })
//         expect InlineDatum(datum) = ownOut.datum
//         expect outDatum: SConfigDatum = datum

//         outDatum.loanVal == loanVal && outDatum.colVal == colVal && has(
//           extra_signatories,
//           o,
//         ) && tAmt == 1
//       }

//       ConClose -> has(extra_signatories, o) && tAmt == -1
//     }
//   }
// }
