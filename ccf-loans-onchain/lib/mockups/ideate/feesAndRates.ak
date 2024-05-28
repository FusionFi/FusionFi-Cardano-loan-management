// use aiken/dict.{to_list, values}
// use aiken/hash.{Blake2b_224, Hash}
// use aiken/list.{any, filter, find, has, head}
// use aiken/time.{PosixTime}
// use aiken/transaction.{
//   InlineDatum, Input, Mint, Output, OutputReference, ScriptContext, Spend,
//   Transaction, find_input, find_script_outputs,
// }
// use aiken/transaction/credential.{
//   Credential, PaymentCredential, Script, ScriptCredential, VerificationKey,
//   VerificationKeyCredential,
// }
// use aiken/transaction/value.{
//   PolicyId, flatten, from_minted_value, lovelace_of, policies, quantity_of,
//   tokens, without_lovelace,
// }

// // Fees And Rates //

// // We want to be able to add fees and rates to the loans
// // this will allow us to earn revenue at every transaction
// // We will start with fixed rates and fees

// // Tx -> every Tx costs 2ADA
// // APR 15% -> charged to date on every payment
// // liquidation costs 10% -> liquidator earns up to 5%?

// // I have actually accounted for variable rates here in theses example functions,
// // To apply variable rates according to asset, we will add these values to the oracle
// // and enable us to adjust these values as necessary

// //                 //
// // Rates Loan Mint //
// //                 //

// validator(o: PolicyId, t: VerificationKeyHash) {
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

//         // Fee
//         any(
//           transaction.outputs,
//           fn(output) {
//             output.address.payment_credential == t && lovelace_of(output.value) >= f * 1000000
//           },
//         )
//       }

//       ABurn -> True
//     }
//   }
// }

// // fn fixed_fee(tx: Transaction, f: Int, o: VerificationKeyHash) -> Bool {
// //   any(
// //     transaction.outputs,
// //     fn(output) {
// //       output.address.payment_credential == o && lovelace_of(output.value) >= f * 1000000
// //     },
// //   )
// // }

// // Helper Function //

// fn calculate_rate(last: PosixTime, new: PosixTime, rate: Int) -> Int {
//   let day = 86400
//   let diff = new - last
//   let daysToCharge = diff / day
//   let dailyRate = rate / 365
//   let apr = dailyRate * rate

//   apr
// }

// //                 //
// // Init Loan Vault //
// //                 //

// validator(p: PolicyId, o: PolicyId, t: VerificationKeyHash) {
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

//         expect
//           any(
//             tx.outputs,
//             fn(output) {
//               let ratePayment =
//                 lovelace_of(loanInput) * calculate_rate(
//                   inDatum.timestamp,
//                   redeemer.timestamp,
//                   r,
//                 )
//               let fee = f * 1000000
//               output.address.payment_credential == t && lovelace_of(
//                 output.value,
//               ) >= ratePayment + fee
//             },
//           )
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

//         expect
//           any(
//             tx.outputs,
//             fn(output) {
//               let minCollateral =
//                 lovelace_of(lDatum.loanValue) * exchangeRate * 1000000
//               let ratePayment =
//                 loanInput * calculate_rate(
//                   inDatum.timestamp,
//                   redeemer.timestamp,
//                   r,
//                 )
//               let fee = f * 1000000
//               output.address.payment_credential == t && lovelace_of(
//                 output.value,
//               ) >= minCollateral + ratePayment + fee
//             },
//           )
//         datum.collateral == d.collateral && datum.collateralValue == newCollateralValue && datum.loanCurrency == d.loanCurrency && datum.loanValue == d.loanValue - r.c && datum.timestamp == r.b && adaOut >= minCollateralValue
//       }
//       // close
//       _ -> {
//         expect
//           any(
//             tx.outputs,
//             fn(output) {
//               let ratePayment =
//                 loanInput * calculate_rate(
//                   inDatum.timestamp,
//                   redeemer.timestamp,
//                   r,
//                 )
//               let fee = f * 1000000
//               output.address.payment_credential == t && lovelace_of(
//                 output.value,
//               ) >= ratePayment + fee
//             },
//           )
//         d.loanValue == 0
//       }
//     }
//   }
// }

// //                       //
// // Variable Oracle Datum //
// //                       //

// type VarODatum {
//   usdAda: Int,
//   timestamp: PosixTime,
//   rate: Int,
// }

// //                 //
// // Variable Oracle //
// //                 //

// validator(o: VerificationKeyHash, p: PolicyId) {
//   fn oracleVault(d: VarODatum, r: OracleAction, c: ScriptContext) -> Bool {
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
//         expect datum: VarODatum = datum

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
