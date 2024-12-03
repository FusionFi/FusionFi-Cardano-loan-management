// use cardano/address.{Address, Script}
// use cardano/assets
// use cardano/transaction.{InlineDatum, NoDatum, Output, Transaction, placeholder}
// use ccfl/types.{CollateralDatum}
// use ref/merkel_yieldin
// use tests/tools as t
// use tests/transactions as tx

// //                     //
// // Yield Deposit Tests //
// //                     //

// test yieldIn() {
//   let inRatio = 1000
//   let outRatio = 1000

//   let inCollateralAmount = 2000
//   let inCollateralValue = 2000

//   let outCollateralAmount = 2000
//   let outCollateralValue = 1000
//   let outYield = 1000

//   let userIn1 = tx.userInput(2024)
//   let configIn = tx.refConfigInput()
//   let oracleIn = tx.refOracleInput(inRatio)
//   let oracleOut = tx.refOracleOutput(outRatio)

//   let inDatum =
//     CollateralDatum {
//       amount: inCollateralAmount,
//       timestamp: 1111111111,
//       yield: 0,
//     }
//   let outDatum =
//     CollateralDatum {
//       amount: outCollateralAmount,
//       timestamp: 1724449574,
//       yield: outYield,
//     }

//   let colIn1 =
//     t.test_input(
//       tx.oref(#"cafe", 1),
//       t.test_output(
//         t.test_script_address(t.refCollateralSpend),
//         assets.merge(
//           assets.from_lovelace(inCollateralValue),
//           t.refLoanTokenValue(),
//         ),
//         InlineDatum(inDatum),
//       ),
//     )

//   let colOut1 =
//     t.test_output(
//       t.test_script_address(t.refCollateralSpend),
//       assets.merge(
//         assets.from_lovelace(outCollateralValue),
//         t.refLoanTokenValue(),
//       ),
//       InlineDatum(outDatum),
//     )

//   let yieldOut =
//     Output {
//       address: Address {
//         payment_credential: Script(t.refYieldSpend),
//         stake_credential: None,
//       },
//       value: assets.from_lovelace(outYield),
//       datum: NoDatum,
//       reference_script: None,
//     }

//   // withdrawl
//   let withdraw0 = tx.withdrawal(t.refYieldIn)
//   let withdrawRedeemer = tx.withdrawRedeemer([0])

//   let tx =
//     Transaction {
//       ..placeholder,
//       reference_inputs: [configIn],
//       inputs: [colIn1, oracleIn, userIn1],
//       outputs: [colOut1, yieldOut, oracleOut],
//       withdrawals: withdraw0,
//     }

//   merkel_yieldin.yieldDeposit.withdraw(
//     t.refConfigMint,
//     withdrawRedeemer,
//     Script(t.refYieldIn),
//     tx,
//   )?
// }
// // test yield_colFail() fail {
// //   let inRatio = 1000
// //   let outRatio = 1000

// //   let inCollateralAmount = 2000
// //   let inCollateralValue = 2000

// //   let outCollateralAmount = 2000
// //   let outCollateralValue = 2000
// //   let outYield = 1000

// //   let userIn1 = tx.userInput(2024)
// //   let configIn = tx.configInput()
// //   let oracleIn = tx.oracleInput(inRatio)
// //   let oracleOut = tx.oracleOutput(outRatio)

// //   let inDatum =
// //     CollateralDatum {
// //       amount: inCollateralAmount,
// //       timestamp: 1111111111,
// //       yield: 0,
// //     }
// //   let outDatum =
// //     CollateralDatum {
// //       amount: outCollateralAmount,
// //       timestamp: 1724449574,
// //       yield: outYield,
// //     }

// //   let colIn1 =
// //     t.test_input(
// //       tx.oref(#"cafe", 1),
// //       t.test_output(
// //         t.test_script_address(t.mCol),
// //         assets.merge(
// //           assets.from_lovelace(inCollateralValue),
// //           t.loanTokenValue(),
// //         ),
// //         InlineDatum(inDatum),
// //       ),
// //     )

// //   let colOut1 =
// //     t.test_output(
// //       t.test_script_address(t.mCol),
// //       assets.merge(assets.from_lovelace(outCollateralValue), t.loanTokenValue()),
// //       InlineDatum(outDatum),
// //     )

// //   let yieldOut =
// //     Output {
// //       address: Address {
// //         payment_credential: Script(#"bebe"),
// //         stake_credential: None,
// //       },
// //       value: assets.from_lovelace(outYield),
// //       datum: NoDatum,
// //       reference_script: None,
// //     }

// //   // withdrawl
// //   let withdraw0 = tx.withdrawal(t.yieldIn)
// //   let withdrawRedeemer = tx.withdrawRedeemer([0])

// //   let tx =
// //     Transaction {
// //       ..placeholder,
// //       reference_inputs: [configIn],
// //       inputs: [colIn1, oracleIn, userIn1],
// //       outputs: [colOut1, yieldOut, oracleOut],
// //       withdrawals: withdraw0,
// //     }

// //   merkel_yieldin.yieldDeposit.withdraw(
// //     t.configMintHash,
// //     withdrawRedeemer,
// //     Script(t.yieldIn),
// //     tx,
// //   )?
// // }

// // test yield_multi() {
// //   let loanValue1 = assets.from_asset(t.loanMintHash, "baba", 1)
// //   let loanValue2 = assets.from_asset(t.loanMintHash, "bbbb", 1)
// //   let loanValue3 = assets.from_asset(t.loanMintHash, "bcbc", 1)

// //   let inRatio = 1000
// //   let outRatio = 1000

// //   let inCollateralAmount = 2000
// //   let inCollateralValue = 2000

// //   let outCollateralAmount = 2000
// //   let outCollateralValue = 1000
// //   let outYield = 1000

// //   let userIn1 = tx.userInput(2024)
// //   let configIn = tx.configInput()
// //   let oracleIn = tx.oracleInput(inRatio)
// //   let oracleOut = tx.oracleOutput(outRatio)

// //   let inDatum =
// //     CollateralDatum {
// //       amount: inCollateralAmount,
// //       timestamp: 1111111111,
// //       yield: 0,
// //     }

// //   let outDatum =
// //     CollateralDatum {
// //       amount: outCollateralAmount,
// //       timestamp: 1724449574,
// //       yield: outYield,
// //     }

// //   let colIn1 =
// //     t.test_input(
// //       tx.oref(#"cafe", 1),
// //       t.test_output(
// //         t.test_script_address(t.mCol),
// //         assets.merge(assets.from_lovelace(inCollateralValue), loanValue1),
// //         InlineDatum(inDatum),
// //       ),
// //     )

// //   let colIn2 =
// //     t.test_input(
// //       tx.oref(#"cafe", 2),
// //       t.test_output(
// //         t.test_script_address(t.mCol),
// //         assets.merge(assets.from_lovelace(inCollateralValue), loanValue2),
// //         InlineDatum(inDatum),
// //       ),
// //     )

// //   let colIn3 =
// //     t.test_input(
// //       tx.oref(#"cafe", 3),
// //       t.test_output(
// //         t.test_script_address(t.mCol),
// //         assets.merge(assets.from_lovelace(inCollateralValue), loanValue3),
// //         InlineDatum(inDatum),
// //       ),
// //     )

// //   let colOut1 =
// //     t.test_output(
// //       t.test_script_address(t.mCol),
// //       assets.merge(assets.from_lovelace(outCollateralValue), loanValue1),
// //       InlineDatum(outDatum),
// //     )

// //   let colOut2 =
// //     t.test_output(
// //       t.test_script_address(t.mCol),
// //       assets.merge(assets.from_lovelace(outCollateralValue), loanValue2),
// //       InlineDatum(outDatum),
// //     )

// //   let colOut3 =
// //     t.test_output(
// //       t.test_script_address(t.mCol),
// //       assets.merge(assets.from_lovelace(outCollateralValue), loanValue3),
// //       InlineDatum(outDatum),
// //     )

// //   let yieldOut1 =
// //     Output {
// //       address: Address {
// //         payment_credential: Script(#"bebe"),
// //         stake_credential: None,
// //       },
// //       value: assets.from_lovelace(outYield),
// //       datum: NoDatum,
// //       reference_script: None,
// //     }

// //   let yieldOut2 =
// //     Output {
// //       address: Address {
// //         payment_credential: Script(#"bebe"),
// //         stake_credential: None,
// //       },
// //       value: assets.from_lovelace(outYield),
// //       datum: NoDatum,
// //       reference_script: None,
// //     }

// //   let yieldOut3 =
// //     Output {
// //       address: Address {
// //         payment_credential: Script(#"bebe"),
// //         stake_credential: None,
// //       },
// //       value: assets.from_lovelace(outYield),
// //       datum: NoDatum,
// //       reference_script: None,
// //     }

// //   // withdrawl
// //   let withdraw0 = tx.withdrawal(t.yieldIn)
// //   let withdrawRedeemer = tx.withdrawRedeemer([0, 2, 4])

// //   let tx =
// //     Transaction {
// //       ..placeholder,
// //       reference_inputs: [configIn],
// //       inputs: [colIn1, colIn2, colIn3, oracleIn, userIn1],
// //       outputs: [
// //         colOut1, yieldOut1, colOut2, yieldOut2, colOut3, yieldOut3, oracleOut,
// //       ],
// //       withdrawals: withdraw0,
// //     }

// //   merkel_yieldin.yieldDeposit.withdraw(
// //     t.configMintHash,
// //     withdrawRedeemer,
// //     Script(t.yieldIn),
// //     tx,
// //   )?
// // }
