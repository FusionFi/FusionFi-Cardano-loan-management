// use aiken/dict
// use aiken/list
// use aiken/transaction.{
//   InlineDatum, Input, NoDatum, Output, ScriptContext, Transaction, WithdrawFrom,
//   placeholder,
// }
// use aiken/transaction/credential.{Inline, ScriptCredential}
// use aiken/transaction/value.{PolicyId}
// use ccfl/helpers.{withBurn, withdraw4}
// use ccfl/types.{
//   CollateralDatum, LoanDatum, MerkelCollateralAction, MerkelConfigDatum,
//   OracleDatum, ScriptHash,
// }
// use tests/tools as t
// use tests/transactions as tx

// //                         //
// // Merkel Collateral Vault //
// //                         //

// validator(cp: PolicyId) {
//   fn spend(_d: CollateralDatum, r: MerkelCollateralAction, c: ScriptContext) {
//     let ScriptContext { transaction, .. } = c
//     let Transaction { reference_inputs, withdrawals, .. } = transaction

//     expect Some(configIn) =
//       list.find(
//         reference_inputs,
//         fn(input) { list.has(value.policies(input.output.value), cp) },
//       )

//     expect InlineDatum(datum) = configIn.output.datum
//     expect cDatum: MerkelConfigDatum = datum

//     expect Some(stakeVal) =
//       cDatum.collateralRedeemers
//         |> list.at(r.i)

//     dict.has_key(withdrawals, Inline(ScriptCredential(stakeVal)))
//   }
// }

// validator(colVal: ScriptHash, lp: PolicyId, op: PolicyId, cp: PolicyId) {
//   fn colBalance(r: List<(Int, Int)>, c: ScriptContext) {
//     expect ScriptContext { transaction, purpose: WithdrawFrom(stake_cred) } = c

//     let Transaction { outputs, reference_inputs, .. } = transaction

//     expect Inline(ScriptCredential(_own_validator)) = stake_cred

//     expect Some(oracleOut) =
//       list.find(
//         outputs,
//         fn(output) { list.has(value.policies(output.value), op) },
//       )

//     expect InlineDatum(datum) = oracleOut.datum
//     expect rDatum: OracleDatum = datum

//     let exchangeRate = rDatum.usdAda

//     expect Some(configIn) =
//       list.find(
//         reference_inputs,
//         fn(input) { list.has(value.policies(input.output.value), cp) },
//       )

//     expect InlineDatum(datum) = configIn.output.datum
//     expect cDatum: MerkelConfigDatum = datum

//     withdraw4(
//       fn(input, output) {
//         expect Some(collateralToken) =
//           list.head(value.flatten(value.without_lovelace(input.value)))

//         expect Some(loanOut) =
//           list.find(
//             outputs,
//             fn(output) {
//               expect Some(loanToken) =
//                 list.head(value.flatten(value.without_lovelace(output.value)))

//               output.address.payment_credential == ScriptCredential(
//                 cDatum.loanVal,
//               ) && loanToken == collateralToken
//             },
//           )

//         expect InlineDatum(datum) = loanOut.datum
//         expect lDatum: LoanDatum = datum

//         let adaOut = value.lovelace_of(output.value) / 1000000

//         let minCollateralValue = lDatum.amount * exchangeRate * ( 50 / 100 )

//         expect list.has(value.policies(output.value), lp)

//         expect InlineDatum(datum) = output.datum
//         expect outDatum: CollateralDatum = datum

//         input.address.payment_credential == output.address.payment_credential && adaOut >= minCollateralValue && outDatum.amount == value.lovelace_of(
//           output.value,
//         ) / exchangeRate / 1000000 && list.has(
//           value.flatten(output.value),
//           collateralToken,
//         )
//       },
//       colVal,
//       r,
//       transaction,
//     )
//   }
// }

// validator(colVal: ScriptHash, _lp: PolicyId, op: PolicyId, cp: PolicyId) {
//   fn colLiquidate(r: List<(Int, Int)>, c: ScriptContext) {
//     expect ScriptContext { transaction, purpose: WithdrawFrom(stake_cred) } = c

//     let Transaction { outputs, reference_inputs, .. } = transaction

//     expect Inline(ScriptCredential(_own_validator)) = stake_cred

//     expect Some(oracleOut) =
//       list.find(
//         outputs,
//         fn(output) { list.has(value.policies(output.value), op) },
//       )

//     expect InlineDatum(datum) = oracleOut.datum
//     expect rDatum: OracleDatum = datum

//     let exchangeRate = rDatum.usdAda

//     expect Some(configIn) =
//       list.find(
//         reference_inputs,
//         fn(input) { list.has(value.policies(input.output.value), cp) },
//       )

//     expect InlineDatum(datum) = configIn.output.datum
//     expect cDatum: MerkelConfigDatum = datum

//     withdraw4(
//       fn(input, output) {
//         expect Some(collateralToken) =
//           list.head(value.flatten(value.without_lovelace(input.value)))

//         expect Some(loanOut) =
//           list.find(
//             outputs,
//             fn(output) {
//               expect Some(loanToken) =
//                 list.head(value.flatten(value.without_lovelace(output.value)))

//               output.address.payment_credential == ScriptCredential(
//                 cDatum.loanVal,
//               ) && loanToken == collateralToken
//             },
//           )

//         expect InlineDatum(datum) = loanOut.datum
//         expect lDatum: LoanDatum = datum

//         let adaOut = value.lovelace_of(output.value) / 1000000

//         let minCollateralValue = lDatum.amount * exchangeRate * ( 85 / 100 )

//         expect InlineDatum(datum) = output.datum
//         expect outDatum: CollateralDatum = datum

//         input.address.payment_credential == output.address.payment_credential && adaOut >= minCollateralValue && outDatum.amount == lDatum.amount && list.has(
//           value.flatten(output.value),
//           collateralToken,
//         )
//       },
//       colVal,
//       r,
//       transaction,
//     )
//   }
// }

// validator(colVal: ScriptHash, lp: PolicyId, op: PolicyId) {
//   fn collateralClose(r: List<Int>, c: ScriptContext) {
//     expect ScriptContext { transaction, purpose: WithdrawFrom(stake_cred) } = c

//     let Transaction { outputs, mint, .. } = transaction

//     expect Inline(ScriptCredential(_own_validator)) = stake_cred

//     expect Some(_oracleOut) =
//       list.find(
//         outputs,
//         fn(output) { list.has(value.policies(output.value), op) },
//       )

//     withBurn(
//       fn(input) {
//         expect InlineDatum(datum) = input.datum
//         expect d: CollateralDatum = datum

//         let loanTokenVal = value.without_lovelace(input.value)
//         expect [(loanTn, 1)] =
//           loanTokenVal
//             |> value.tokens(lp)
//             |> dict.to_list()

//         expect Some(burnVal) =
//           value.zero()
//             |> value.add(lp, loanTn, -2)
//             |> value.flatten()
//             |> list.head()

//         let burns =
//           mint
//             |> value.from_minted_value()
//             |> value.flatten()

//         expect list.has(burns, burnVal)
//         d.amount == 0
//       },
//       colVal,
//       r,
//       transaction,
//     )
//   }
// }

// //                 //
// // Validator Tests //
// //                 //

// test balance_single() {
//   let test_owner = #"face"

//   // let test_user = #"cafe"
//   let oref1 = t.test_oref(#"face", 1)
//   let cref1 = t.test_oref(#"cafe", 2)
//   let rref = t.test_oref(#"dead", 6)
//   let uref1 = t.test_oref(#"beef", 4)
//   let href1 = t.test_oref(#"feed", 3)

//   // let collateralAction = tx.merkelCollateralAction(0)
//   let configDatum =
//     tx.mConfigDatum(
//       t.merkelLoanSpend,
//       t.merkelCollateralSpend,
//       t.rewardsMintHash,
//       t.oracleValHash,
//       [t.merkelLoanBalance, t.merkelLoanLiquidate, t.merkelLoanClose],
//       [t.merkelCollateralBalance],
//     )
//   let configInDatum = InlineDatum(configDatum)

//   let loanDatum1 = tx.loanDatum(1000, 15, 1000, 0, 1111111114)
//   let loanInDatum = InlineDatum(loanDatum1)
//   let loanInValue = t.loanTokenValue()

//   let loanDatum2 = tx.loanDatum(1000, 15, 1000, 0, 1111111115)
//   let loanOutDatum = InlineDatum(loanDatum2)
//   let loanOutValue = t.loanTokenValue()

//   let collateralDatum1 = tx.collateralDatum(1000, 12)
//   let colInDatum = InlineDatum(collateralDatum1)
//   let colInValue = value.merge(t.makeAdaValue(2000), t.loanTokenValue())

//   let collateralDatum2 = tx.collateralDatum(1000, 12)
//   let colOutDatum = InlineDatum(collateralDatum2)
//   let colOutValue = value.merge(t.makeAdaValue(2000), t.loanTokenValue())

//   let oracleInDatum = tx.oracleDatum(2, 11111112, 15, 2)
//   let oracleOutDatum = tx.oracleDatum(2, 11111114, 15, 2)

//   let oInDatum = InlineDatum(oracleInDatum)
//   let oOutDatum = InlineDatum(oracleOutDatum)

//   let noDatum = NoDatum

//   let withdraw0 =
//     dict.from_ascending_list(
//       [(t.create_stake_credential(t.merkelCollateralBalance), 0)],
//       t.stakeCompare,
//     )

//   let redeemerList =
//     [(0, 0)]

//   let loanIn1 =
//     t.test_input(
//       oref1,
//       t.test_output(
//         t.test_script_address(t.merkelLoanSpend),
//         loanInValue,
//         loanInDatum,
//       ),
//     )

//   let colIn1 =
//     t.test_input(
//       href1,
//       t.test_output(
//         t.test_script_address(t.merkelCollateralSpend),
//         colInValue,
//         colInDatum,
//       ),
//     )

//   let userIn1 =
//     t.test_input(
//       uref1,
//       t.test_output(t.test_address(#"cafe"), t.makeAdaValue(2010), noDatum),
//     )

//   let configIn =
//     t.test_input(
//       cref1,
//       t.test_output(
//         t.test_script_address(t.configValHash),
//         t.configValue(),
//         configInDatum,
//       ),
//     )

//   let oracleIn =
//     t.test_input(
//       rref,
//       t.test_output(
//         t.test_script_address(t.oracleValHash),
//         t.oracleValue(),
//         oInDatum,
//       ),
//     )

//   let oracleOut =
//     t.test_output(
//       t.test_script_address(t.oracleValHash),
//       t.oracleValue(),
//       oOutDatum,
//     )

//   let loanOut1 =
//     t.test_output(
//       t.test_script_address(t.merkelLoanSpend),
//       loanOutValue,
//       loanOutDatum,
//     )

//   let colOut1 =
//     t.test_output(
//       t.test_script_address(t.merkelCollateralSpend),
//       colOutValue,
//       colOutDatum,
//     )

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       extra_signatories: [test_owner],
//       inputs: [colIn1, loanIn1, oracleIn, userIn1],
//       outputs: [colOut1, loanOut1, oracleOut],
//       withdrawals: withdraw0,
//     }

//   let ctx5 =
//     ScriptContext {
//       purpose: t.withPurpose(t.merkelCollateralBalance),
//       transaction: tx,
//     }

//   colBalance(
//     t.merkelCollateralSpend,
//     t.loanMintHash,
//     t.oracleMintHash,
//     t.configMintHash,
//     redeemerList,
//     ctx5,
//   )?
// }

// test balance_multi() {
//   let test_owner = #"face"

//   // let test_user = #"cafe"
//   let oref1 = t.test_oref(#"face", 1)
//   let oref2 = t.test_oref(#"face", 2)
//   let oref3 = t.test_oref(#"face", 3)
//   let cref1 = t.test_oref(#"cafe", 2)
//   let rref = t.test_oref(#"dead", 6)
//   let uref1 = t.test_oref(#"beef", 4)
//   let href1 = t.test_oref(#"feed", 3)
//   let href2 = t.test_oref(#"feed", 2)
//   let href3 = t.test_oref(#"feed", 1)

//   // let collateralAction = tx.merkelCollateralAction(0)
//   let configDatum =
//     tx.mConfigDatum(
//       t.merkelLoanSpend,
//       t.merkelCollateralSpend,
//       t.rewardsMintHash,
//       t.oracleValHash,
//       [t.merkelLoanBalance, t.merkelLoanLiquidate, t.merkelLoanClose],
//       [t.merkelCollateralBalance],
//     )
//   let configInDatum = InlineDatum(configDatum)

//   let loanDatum1 = tx.loanDatum(1000, 15, 1000, 0, 1111111114)
//   let loanInDatum = InlineDatum(loanDatum1)
//   let loanInValue = t.loanTokenValue()

//   let loanDatum2 = tx.loanDatum(1000, 15, 1000, 0, 1111111115)
//   let loanOutDatum = InlineDatum(loanDatum2)
//   let loanOutValue = t.loanTokenValue()

//   let collateralDatum1 = tx.collateralDatum(1000, 12)
//   let colInDatum = InlineDatum(collateralDatum1)
//   let colInValue = value.merge(t.makeAdaValue(2000), t.loanTokenValue())

//   let collateralDatum2 = tx.collateralDatum(1000, 12)
//   let colOutDatum = InlineDatum(collateralDatum2)
//   let colOutValue = value.merge(t.makeAdaValue(2000), t.loanTokenValue())

//   let oracleInDatum = tx.oracleDatum(2, 11111112, 15, 2)
//   let oracleOutDatum = tx.oracleDatum(2, 11111114, 15, 2)

//   let oInDatum = InlineDatum(oracleInDatum)
//   let oOutDatum = InlineDatum(oracleOutDatum)

//   let noDatum = NoDatum

//   let withdraw0 =
//     dict.from_ascending_list(
//       [(t.create_stake_credential(t.merkelCollateralBalance), 0)],
//       t.stakeCompare,
//     )

//   let redeemerList =
//     [(5, 4), (6, 5), (7, 6)]

//   let loanIn1 =
//     t.test_input(
//       oref1,
//       t.test_output(
//         t.test_script_address(t.merkelLoanSpend),
//         loanInValue,
//         loanInDatum,
//       ),
//     )
//   let loanIn2 =
//     t.test_input(
//       oref2,
//       t.test_output(
//         t.test_script_address(t.merkelLoanSpend),
//         loanInValue,
//         loanInDatum,
//       ),
//     )

//   let loanIn3 =
//     t.test_input(
//       oref3,
//       t.test_output(
//         t.test_script_address(t.merkelLoanSpend),
//         loanInValue,
//         loanInDatum,
//       ),
//     )

//   let colIn1 =
//     t.test_input(
//       href1,
//       t.test_output(
//         t.test_script_address(t.merkelCollateralSpend),
//         colInValue,
//         colInDatum,
//       ),
//     )

//   let colIn2 =
//     t.test_input(
//       href2,
//       t.test_output(
//         t.test_script_address(t.merkelCollateralSpend),
//         colInValue,
//         colInDatum,
//       ),
//     )

//   let colIn3 =
//     t.test_input(
//       href3,
//       t.test_output(
//         t.test_script_address(t.merkelCollateralSpend),
//         colInValue,
//         colInDatum,
//       ),
//     )

//   let userIn1 =
//     t.test_input(
//       uref1,
//       t.test_output(t.test_address(#"cafe"), t.makeAdaValue(2010), noDatum),
//     )

//   let configIn =
//     t.test_input(
//       cref1,
//       t.test_output(
//         t.test_script_address(t.configValHash),
//         t.configValue(),
//         configInDatum,
//       ),
//     )

//   let oracleIn =
//     t.test_input(
//       rref,
//       t.test_output(
//         t.test_script_address(t.oracleValHash),
//         t.oracleValue(),
//         oInDatum,
//       ),
//     )

//   let oracleOut =
//     t.test_output(
//       t.test_script_address(t.oracleValHash),
//       t.oracleValue(),
//       oOutDatum,
//     )

//   let loanOut1 =
//     t.test_output(
//       t.test_script_address(t.merkelLoanSpend),
//       loanOutValue,
//       loanOutDatum,
//     )
//   let loanOut2 =
//     t.test_output(
//       t.test_script_address(t.merkelLoanSpend),
//       loanOutValue,
//       loanOutDatum,
//     )

//   let loanOut3 =
//     t.test_output(
//       t.test_script_address(t.merkelLoanSpend),
//       loanOutValue,
//       loanOutDatum,
//     )

//   let colOut1 =
//     t.test_output(
//       t.test_script_address(t.merkelCollateralSpend),
//       colOutValue,
//       colOutDatum,
//     )

//   let colOut2 =
//     t.test_output(
//       t.test_script_address(t.merkelCollateralSpend),
//       colOutValue,
//       colOutDatum,
//     )

//   let colOut3 =
//     t.test_output(
//       t.test_script_address(t.merkelCollateralSpend),
//       colOutValue,
//       colOutDatum,
//     )

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       extra_signatories: [test_owner],
//       inputs: [
//         loanIn1,
//         loanIn2,
//         loanIn3,
//         oracleIn,
//         userIn1,
//         colIn1,
//         colIn2,
//         colIn3,
//       ],
//       outputs: [
//         loanOut1,
//         loanOut2,
//         loanOut3,
//         oracleOut,
//         colOut1,
//         colOut2,
//         colOut3,
//       ],
//       withdrawals: withdraw0,
//     }

//   let ctx5 =
//     ScriptContext {
//       purpose: t.withPurpose(t.merkelCollateralBalance),
//       transaction: tx,
//     }

//   colBalance(
//     t.merkelCollateralSpend,
//     t.loanMintHash,
//     t.oracleMintHash,
//     t.configMintHash,
//     redeemerList,
//     ctx5,
//   )?
// }

// test liquidate_single() {
//   let test_owner = #"face"

//   // let test_user = #"cafe"
//   let oref1 = t.test_oref(#"face", 1)
//   let cref1 = t.test_oref(#"cafe", 2)
//   let rref = t.test_oref(#"dead", 6)
//   let uref1 = t.test_oref(#"beef", 4)
//   let href1 = t.test_oref(#"feed", 3)

//   // let loanAction = tx.merkelLoanAction(1)
//   let configDatum =
//     tx.mConfigDatum(
//       t.merkelLoanSpend,
//       t.collateralValHash,
//       t.rewardsMintHash,
//       t.oracleValHash,
//       [t.merkelLoanBalance, t.merkelLoanLiquidate, t.merkelLoanClose],
//       [t.merkelCollateralBalance, t.merkelCollateralLiquidate],
//     )
//   let configInDatum = InlineDatum(configDatum)

//   let loanDatum1 = tx.loanDatum(1000, 15, 1000, 0, 1111111114)
//   let loanInDatum = InlineDatum(loanDatum1)
//   let loanInValue = t.loanTokenValue()

//   let loanDatum2 = tx.loanDatum(0, 15, 1000, 0, 1111111115)
//   let loanOutDatum = InlineDatum(loanDatum2)
//   let loanOutValue = t.loanTokenValue()

//   let collateralDatum1 = tx.collateralDatum(1000, 12)
//   let colInDatum = InlineDatum(collateralDatum1)
//   let colInValue = value.merge(t.makeAdaValue(2000), t.loanTokenValue())

//   let collateralDatum2 = tx.collateralDatum(0, 12)
//   let colOutDatum = InlineDatum(collateralDatum2)
//   let colOutValue = value.merge(t.makeAdaValue(2), t.loanTokenValue())

//   let oracleInDatum = tx.oracleDatum(2, 11111112, 15, 2)
//   let oracleOutDatum = tx.oracleDatum(2, 11111114, 15, 2)

//   let oInDatum = InlineDatum(oracleInDatum)
//   let oOutDatum = InlineDatum(oracleOutDatum)

//   let noDatum = NoDatum

//   let withdraw0 =
//     dict.from_ascending_list(
//       [(t.create_stake_credential(t.merkelCollateralLiquidate), 0)],
//       t.stakeCompare,
//     )

//   let redeemerList =
//     [(3, 2)]

//   let loanIn1 =
//     t.test_input(
//       oref1,
//       t.test_output(
//         t.test_script_address(t.merkelLoanSpend),
//         loanInValue,
//         loanInDatum,
//       ),
//     )

//   let colIn1 =
//     t.test_input(
//       href1,
//       t.test_output(
//         t.test_script_address(t.merkelCollateralSpend),
//         colInValue,
//         colInDatum,
//       ),
//     )

//   let userIn1 =
//     t.test_input(
//       uref1,
//       t.test_output(t.test_address(#"cafe"), t.makeAdaValue(2010), noDatum),
//     )

//   let configIn =
//     t.test_input(
//       cref1,
//       t.test_output(
//         t.test_script_address(t.configValHash),
//         t.configValue(),
//         configInDatum,
//       ),
//     )

//   let oracleIn =
//     t.test_input(
//       rref,
//       t.test_output(
//         t.test_script_address(t.oracleValHash),
//         t.oracleValue(),
//         oInDatum,
//       ),
//     )

//   let oracleOut =
//     t.test_output(
//       t.test_script_address(t.oracleValHash),
//       t.oracleValue(),
//       oOutDatum,
//     )

//   let loanOut1 =
//     t.test_output(
//       t.test_script_address(t.merkelLoanSpend),
//       loanOutValue,
//       loanOutDatum,
//     )

//   let colOut1 =
//     t.test_output(
//       t.test_script_address(t.merkelCollateralSpend),
//       colOutValue,
//       colOutDatum,
//     )

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       extra_signatories: [test_owner],
//       inputs: [loanIn1, oracleIn, userIn1, colIn1],
//       outputs: [loanOut1, oracleOut, colOut1],
//       withdrawals: withdraw0,
//     }

//   let ctx5 =
//     ScriptContext {
//       purpose: t.withPurpose(t.merkelCollateralLiquidate),
//       transaction: tx,
//     }

//   colLiquidate(
//     t.merkelCollateralSpend,
//     t.loanMintHash,
//     t.oracleMintHash,
//     t.configMintHash,
//     redeemerList,
//     ctx5,
//   )?
// }

// test liquidate_multi() {
//   let test_owner = #"face"

//   // let test_user = #"cafe"
//   let oref1 = t.test_oref(#"face", 1)
//   let oref2 = t.test_oref(#"face", 2)
//   let oref3 = t.test_oref(#"face", 3)
//   let cref1 = t.test_oref(#"cafe", 2)
//   let rref = t.test_oref(#"dead", 6)
//   let uref1 = t.test_oref(#"beef", 4)
//   let href1 = t.test_oref(#"feed", 3)
//   let href2 = t.test_oref(#"feed", 2)
//   let href3 = t.test_oref(#"feed", 1)

//   // let loanAction = tx.merkelLoanAction(1)
//   let configDatum =
//     tx.mConfigDatum(
//       t.merkelLoanSpend,
//       t.collateralValHash,
//       t.rewardsMintHash,
//       t.oracleValHash,
//       [t.merkelLoanBalance, t.merkelLoanLiquidate, t.merkelLoanClose],
//       [t.merkelCollateralBalance, t.merkelCollateralLiquidate],
//     )
//   let configInDatum = InlineDatum(configDatum)

//   let loanDatum1 = tx.loanDatum(1000, 15, 1000, 0, 1111111114)
//   let loanInDatum = InlineDatum(loanDatum1)
//   let loanInValue = t.loanTokenValue()

//   let loanDatum2 = tx.loanDatum(0, 15, 1000, 0, 1111111115)
//   let loanOutDatum = InlineDatum(loanDatum2)
//   let loanOutValue = t.loanTokenValue()

//   let collateralDatum1 = tx.collateralDatum(1000, 12)
//   let colInDatum = InlineDatum(collateralDatum1)
//   let colInValue = value.merge(t.makeAdaValue(2000), t.loanTokenValue())

//   let collateralDatum2 = tx.collateralDatum(0, 12)
//   let colOutDatum = InlineDatum(collateralDatum2)
//   let colOutValue = value.merge(t.makeAdaValue(2), t.loanTokenValue())

//   let oracleInDatum = tx.oracleDatum(2, 11111112, 15, 2)
//   let oracleOutDatum = tx.oracleDatum(2, 11111114, 15, 2)

//   let oInDatum = InlineDatum(oracleInDatum)
//   let oOutDatum = InlineDatum(oracleOutDatum)

//   let noDatum = NoDatum

//   let withdraw0 =
//     dict.from_ascending_list(
//       [(t.create_stake_credential(t.merkelCollateralLiquidate), 0)],
//       t.stakeCompare,
//     )

//   let redeemerList =
//     [(5, 4), (6, 5), (7, 6)]

//   let loanIn1 =
//     t.test_input(
//       oref1,
//       t.test_output(
//         t.test_script_address(t.merkelLoanSpend),
//         loanInValue,
//         loanInDatum,
//       ),
//     )
//   let loanIn2 =
//     t.test_input(
//       oref2,
//       t.test_output(
//         t.test_script_address(t.merkelLoanSpend),
//         loanInValue,
//         loanInDatum,
//       ),
//     )

//   let loanIn3 =
//     t.test_input(
//       oref3,
//       t.test_output(
//         t.test_script_address(t.merkelLoanSpend),
//         loanInValue,
//         loanInDatum,
//       ),
//     )

//   let colIn1 =
//     t.test_input(
//       href1,
//       t.test_output(
//         t.test_script_address(t.merkelCollateralSpend),
//         colInValue,
//         colInDatum,
//       ),
//     )

//   let colIn2 =
//     t.test_input(
//       href2,
//       t.test_output(
//         t.test_script_address(t.merkelCollateralSpend),
//         colInValue,
//         colInDatum,
//       ),
//     )

//   let colIn3 =
//     t.test_input(
//       href3,
//       t.test_output(
//         t.test_script_address(t.merkelCollateralSpend),
//         colInValue,
//         colInDatum,
//       ),
//     )

//   let userIn1 =
//     t.test_input(
//       uref1,
//       t.test_output(t.test_address(#"cafe"), t.makeAdaValue(2010), noDatum),
//     )

//   let configIn =
//     t.test_input(
//       cref1,
//       t.test_output(
//         t.test_script_address(t.configValHash),
//         t.configValue(),
//         configInDatum,
//       ),
//     )

//   let oracleIn =
//     t.test_input(
//       rref,
//       t.test_output(
//         t.test_script_address(t.oracleValHash),
//         t.oracleValue(),
//         oInDatum,
//       ),
//     )

//   let oracleOut =
//     t.test_output(
//       t.test_script_address(t.oracleValHash),
//       t.oracleValue(),
//       oOutDatum,
//     )

//   let loanOut1 =
//     t.test_output(
//       t.test_script_address(t.merkelLoanSpend),
//       loanOutValue,
//       loanOutDatum,
//     )
//   let loanOut2 =
//     t.test_output(
//       t.test_script_address(t.merkelLoanSpend),
//       loanOutValue,
//       loanOutDatum,
//     )

//   let loanOut3 =
//     t.test_output(
//       t.test_script_address(t.merkelLoanSpend),
//       loanOutValue,
//       loanOutDatum,
//     )

//   let colOut1 =
//     t.test_output(
//       t.test_script_address(t.merkelCollateralSpend),
//       colOutValue,
//       colOutDatum,
//     )

//   let colOut2 =
//     t.test_output(
//       t.test_script_address(t.merkelCollateralSpend),
//       colOutValue,
//       colOutDatum,
//     )

//   let colOut3 =
//     t.test_output(
//       t.test_script_address(t.merkelCollateralSpend),
//       colOutValue,
//       colOutDatum,
//     )

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       extra_signatories: [test_owner],
//       inputs: [
//         loanIn1,
//         loanIn2,
//         loanIn3,
//         oracleIn,
//         userIn1,
//         colIn1,
//         colIn2,
//         colIn3,
//       ],
//       outputs: [
//         loanOut1,
//         loanOut2,
//         loanOut3,
//         oracleOut,
//         colOut1,
//         colOut2,
//         colOut3,
//       ],
//       withdrawals: withdraw0,
//     }

//   let ctx5 =
//     ScriptContext {
//       purpose: t.withPurpose(t.merkelCollateralLiquidate),
//       transaction: tx,
//     }

//   colLiquidate(
//     t.merkelCollateralSpend,
//     t.loanMintHash,
//     t.oracleMintHash,
//     t.configMintHash,
//     redeemerList,
//     ctx5,
//   )?
// }

// test close_single() {
//   let test_owner = #"face"

//   // let test_user = #"cafe"
//   let oref1 = t.test_oref(#"face", 1)
//   let cref1 = t.test_oref(#"cafe", 2)
//   let rref = t.test_oref(#"dead", 6)
//   let uref1 = t.test_oref(#"beef", 4)
//   let href1 = t.test_oref(#"feed", 3)

//   // let loanAction = tx.merkelLoanAction(2)
//   let configDatum =
//     tx.mConfigDatum(
//       t.merkelLoanSpend,
//       t.collateralValHash,
//       t.rewardsMintHash,
//       t.oracleValHash,
//       [t.merkelLoanBalance, t.merkelLoanLiquidate, t.merkelLoanClose],
//       [
//         t.merkelCollateralBalance,
//         t.merkelCollateralLiquidate,
//         t.merkelCollateralClose,
//       ],
//     )
//   let configInDatum = InlineDatum(configDatum)

//   let loanDatum1 = tx.loanDatum(0, 15, 1000, 0, 1111111114)
//   let loanInDatum = InlineDatum(loanDatum1)
//   let loanInValue = t.loanTokenValue()

//   // let loanDatum2 = tx.loanDatum(0, 15, 1000, 0, 1111111115)
//   // let loanOutDatum = InlineDatum(loanDatum2)
//   // let loanOutValue = t.loanTokenValue()
//   let collateralDatum1 = tx.collateralDatum(0, 12)
//   let colInDatum = InlineDatum(collateralDatum1)
//   let colInValue = value.merge(t.makeAdaValue(2000), t.loanTokenValue())

//   // let collateralDatum2 = tx.collateralDatum(1000, 12)
//   // let colOutDatum = InlineDatum(collateralDatum2)
//   // let colOutValue = value.merge(t.makeAdaValue(1000), t.loanTokenValue())
//   let oracleInDatum = tx.oracleDatum(2, 11111112, 15, 2)
//   let oracleOutDatum = tx.oracleDatum(2, 11111114, 15, 2)

//   let oInDatum = InlineDatum(oracleInDatum)
//   let oOutDatum = InlineDatum(oracleOutDatum)

//   let noDatum = NoDatum

//   let withdraw0 =
//     dict.from_ascending_list(
//       [(t.create_stake_credential(t.merkelCollateralClose), 0)],
//       t.stakeCompare,
//     )

//   let redeemerList =
//     [3]

//   let loanIn1 =
//     t.test_input(
//       oref1,
//       t.test_output(
//         t.test_script_address(t.merkelLoanSpend),
//         loanInValue,
//         loanInDatum,
//       ),
//     )

//   let colIn1 =
//     t.test_input(
//       href1,
//       t.test_output(
//         t.test_script_address(t.merkelCollateralSpend),
//         colInValue,
//         colInDatum,
//       ),
//     )

//   let userIn1 =
//     t.test_input(
//       uref1,
//       t.test_output(t.test_address(#"cafe"), t.makeAdaValue(2010), noDatum),
//     )

//   let configIn =
//     t.test_input(
//       cref1,
//       t.test_output(
//         t.test_script_address(t.configValHash),
//         t.configValue(),
//         configInDatum,
//       ),
//     )

//   let oracleIn =
//     t.test_input(
//       rref,
//       t.test_output(
//         t.test_script_address(t.oracleValHash),
//         t.oracleValue(),
//         oInDatum,
//       ),
//     )

//   let oracleOut =
//     t.test_output(
//       t.test_script_address(t.oracleValHash),
//       t.oracleValue(),
//       oOutDatum,
//     )

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       extra_signatories: [test_owner],
//       inputs: [loanIn1, oracleIn, userIn1, colIn1],
//       outputs: [oracleOut],
//       mint: value.to_minted_value(t.loanBurnValue()),
//       withdrawals: withdraw0,
//     }

//   let ctx5 =
//     ScriptContext {
//       purpose: t.withPurpose(t.merkelCollateralClose),
//       transaction: tx,
//     }

//   collateralClose(
//     t.merkelCollateralSpend,
//     t.loanMintHash,
//     t.oracleMintHash,
//     redeemerList,
//     ctx5,
//   )?
// }

// test close_multi() {
//   let test_owner = #"face"

//   // let test_user = #"cafe"
//   let oref1 = t.test_oref(#"face", 1)
//   let oref2 = t.test_oref(#"face", 2)
//   let oref3 = t.test_oref(#"face", 3)
//   let cref1 = t.test_oref(#"cafe", 2)
//   let rref = t.test_oref(#"dead", 6)
//   let uref1 = t.test_oref(#"beef", 4)
//   let href1 = t.test_oref(#"feed", 3)
//   let href2 = t.test_oref(#"feed", 2)
//   let href3 = t.test_oref(#"feed", 1)

//   // let loanAction = tx.merkelLoanAction(2)
//   let configDatum =
//     tx.mConfigDatum(
//       t.merkelLoanSpend,
//       t.collateralValHash,
//       t.rewardsMintHash,
//       t.oracleValHash,
//       [t.merkelLoanBalance, t.merkelLoanLiquidate, t.merkelLoanClose],
//       [
//         t.merkelCollateralBalance,
//         t.merkelCollateralLiquidate,
//         t.merkelCollateralClose,
//       ],
//     )
//   let configInDatum = InlineDatum(configDatum)

//   let loanDatum1 = tx.loanDatum(0, 15, 1000, 0, 1111111114)
//   let loanInDatum = InlineDatum(loanDatum1)
//   let loanInValue = t.loanTokenValue()

//   // let loanDatum2 = tx.loanDatum(0, 15, 1000, 0, 1111111115)
//   // let loanOutDatum = InlineDatum(loanDatum2)
//   // let loanOutValue = t.loanTokenValue()
//   let collateralDatum1 = tx.collateralDatum(0, 12)
//   let colInDatum = InlineDatum(collateralDatum1)
//   let colInValue = value.merge(t.makeAdaValue(2000), t.loanTokenValue())

//   // let collateralDatum2 = tx.collateralDatum(1000, 12)
//   // let colOutDatum = InlineDatum(collateralDatum2)
//   // let colOutValue = value.merge(t.makeAdaValue(1000), t.loanTokenValue())
//   let oracleInDatum = tx.oracleDatum(2, 11111112, 15, 2)
//   let oracleOutDatum = tx.oracleDatum(2, 11111114, 15, 2)

//   let oInDatum = InlineDatum(oracleInDatum)
//   let oOutDatum = InlineDatum(oracleOutDatum)

//   let noDatum = NoDatum

//   let withdraw0 =
//     dict.from_ascending_list(
//       [(t.create_stake_credential(t.merkelCollateralClose), 0)],
//       t.stakeCompare,
//     )

//   let redeemerList =
//     [5, 6, 7]

//   let loanIn1 =
//     t.test_input(
//       oref1,
//       t.test_output(
//         t.test_script_address(t.merkelLoanSpend),
//         loanInValue,
//         loanInDatum,
//       ),
//     )
//   let loanIn2 =
//     t.test_input(
//       oref2,
//       t.test_output(
//         t.test_script_address(t.merkelLoanSpend),
//         loanInValue,
//         loanInDatum,
//       ),
//     )

//   let loanIn3 =
//     t.test_input(
//       oref3,
//       t.test_output(
//         t.test_script_address(t.merkelLoanSpend),
//         loanInValue,
//         loanInDatum,
//       ),
//     )

//   let colIn1 =
//     t.test_input(
//       href1,
//       t.test_output(
//         t.test_script_address(t.merkelCollateralSpend),
//         colInValue,
//         colInDatum,
//       ),
//     )

//   let colIn2 =
//     t.test_input(
//       href2,
//       t.test_output(
//         t.test_script_address(t.merkelCollateralSpend),
//         colInValue,
//         colInDatum,
//       ),
//     )

//   let colIn3 =
//     t.test_input(
//       href3,
//       t.test_output(
//         t.test_script_address(t.merkelCollateralSpend),
//         colInValue,
//         colInDatum,
//       ),
//     )

//   let userIn1 =
//     t.test_input(
//       uref1,
//       t.test_output(t.test_address(#"cafe"), t.makeAdaValue(2010), noDatum),
//     )

//   let configIn =
//     t.test_input(
//       cref1,
//       t.test_output(
//         t.test_script_address(t.configValHash),
//         t.configValue(),
//         configInDatum,
//       ),
//     )

//   let oracleIn =
//     t.test_input(
//       rref,
//       t.test_output(
//         t.test_script_address(t.oracleValHash),
//         t.oracleValue(),
//         oInDatum,
//       ),
//     )

//   let oracleOut =
//     t.test_output(
//       t.test_script_address(t.oracleValHash),
//       t.oracleValue(),
//       oOutDatum,
//     )

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       extra_signatories: [test_owner],
//       inputs: [
//         loanIn1,
//         loanIn2,
//         loanIn3,
//         oracleIn,
//         userIn1,
//         colIn1,
//         colIn2,
//         colIn3,
//       ],
//       outputs: [oracleOut],
//       mint: value.to_minted_value(t.loanBurnValue()),
//       withdrawals: withdraw0,
//     }

//   let ctx5 =
//     ScriptContext {
//       purpose: t.withPurpose(t.merkelCollateralClose),
//       transaction: tx,
//     }

//   collateralClose(
//     t.merkelCollateralSpend,
//     t.loanMintHash,
//     t.oracleMintHash,
//     redeemerList,
//     ctx5,
//   )?
// }
