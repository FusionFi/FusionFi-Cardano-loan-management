// use cardano/address.{Script}
// use cardano/assets
// use cardano/transaction.{InlineDatum, Transaction, placeholder}
// use ccfl/types.{CollateralDatum, LoanDatum}
// use ref/merkel_balance
// use tests/tools as t
// use tests/transactions as tx

// //                         //
// // Balance Validator Tests //
// //                         //

// test merkel_balance_single() {
//   let inRatio = 1000
//   let outRatio = 1000

//   let inLoanAmount = 1000
//   let inCollateralAmount = 2000
//   let inCollateralValue = 2000

//   let outLoanAmount = 1000
//   let outCollateralAmount = 2000
//   let outCollateralValue = 2000

//   let loanDatumIn =
//     LoanDatum {
//       amount: inLoanAmount,
//       rewards: inLoanAmount,
//       term: 12,
//       timestamp: 1111111111,
//       oracle: #"beef",
//     }

//   let loanDatumOut =
//     LoanDatum {
//       amount: inLoanAmount,
//       rewards: inLoanAmount,
//       term: 12,
//       timestamp: 1111111112,
//       oracle: #"beef",
//     }

//   let colDatumIn =
//     CollateralDatum {
//       amount: inCollateralAmount,
//       timestamp: 1111111111,
//       yield: 0,
//     }
//   let colDatumOut =
//     CollateralDatum {
//       amount: outCollateralAmount,
//       timestamp: 1111111112,
//       yield: 0,
//     }

//   let test_owner = #"face"

//   // withdrawl
//   let withdraw0 = tx.withdrawal(t.refBalance)

//   let bRedeemer = tx.withdrawRedeemer([0])

//   let loanIn1 =
//     t.test_input(
//       tx.oref(#"baba", 1),
//       t.test_output(
//         t.test_script_address(t.refLoanSpend),
//         t.refLoanValue(),
//         InlineDatum(loanDatumIn),
//       ),
//     )

//   let colIn1 =
//     t.test_input(
//       tx.oref(#"dada", 1),
//       t.test_output(
//         t.test_script_address(t.refCollateralSpend),
//         t.refCollateralValue(2002),
//         InlineDatum(colDatumIn),
//       ),
//     )

//   let userIn1 = tx.userInput(2024)

//   let configIn =
//     t.test_input(
//       tx.oref(#"aeae", 1),
//       t.test_output(
//         t.test_script_address(t.refConfigSpend),
//         t.refConfigValue(),
//         tx.refConfigDatumIn(),
//       ),
//     )

//   let oracleIn =
//     t.test_input(
//       tx.oref(#"aaaa", 1),
//       t.test_output(
//         t.test_script_address(t.refOracleSpend),
//         t.refOracleValue(),
//         InlineDatum(
//           tx.oracleDatum(inRatio, 1111111111, 1000000, 1000000, "USD"),
//         ),
//       ),
//     )

//   let oracleOut =
//     t.test_output(
//       t.test_script_address(t.refOracleSpend),
//       t.refOracleValue(),
//       InlineDatum(tx.oracleDatum(outRatio, 1111111111, 1000000, 1000000, "USD")),
//     )

//   let loanOut1 =
//     t.test_output(
//       t.test_script_address(t.refLoanSpend),
//       t.refLoanValue(),
//       InlineDatum(loanDatumOut),
//     )

//   let colOut1 =
//     t.test_output(
//       t.test_script_address(t.refCollateralSpend),
//       t.refCollateralValue(2002),
//       InlineDatum(colDatumOut),
//     )

//   let tx =
//     Transaction {
//       ..placeholder,
//       reference_inputs: [configIn],
//       inputs: [colIn1, loanIn1, oracleIn, userIn1],
//       outputs: [colOut1, loanOut1, oracleOut],
//       withdrawals: withdraw0,
//     }

//   merkel_balance.balance.withdraw(
//     t.refOracleMint,
//     t.refConfigMint,
//     bRedeemer,
//     Script(t.refBalance),
//     tx,
//   )?
// }
// // test balance_colAmtFail() {
// //   let inRatio = 1000
// //   let outRatio = 1000

// //   let inLoanAmount = 1000
// //   let inCollateralAmount = 2000
// //   let inCollateralValue = 2000

// //   let outLoanAmount = 1000
// //   let outCollateralAmount = 100
// //   let outCollateralValue = 4000

// //   let test_owner = #"face"

// //   // withdrawl
// //   let withdraw0 = tx.withdrawal(t.merkelBalance)

// //   let bRedeemer = tx.withdrawRedeemer([0])

// //   let loanIn1 = tx.mLoanInput(1, inLoanAmount)
// //   let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue, 0)

// //   let userIn1 = tx.userInput(2024)
// //   let configIn = tx.configInput()
// //   let oracleIn = tx.oracleInput(inRatio)
// //   let oracleOut = tx.oracleOutput(outRatio)

// //   let loanOut1 = tx.mLoanOutput(outLoanAmount)
// //   let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue, 0)

// //   let tx =
// //     Transaction {
// //       ..placeholder,
// //       reference_inputs: [configIn],
// //       extra_signatories: [test_owner],
// //       inputs: [colIn1, loanIn1, oracleIn, userIn1],
// //       outputs: [colOut1, loanOut1, oracleOut],
// //       withdrawals: withdraw0,
// //     }

// //   trace @"VULNERABILITY"
// //   trace @"Vou can change the collateralDatum Amount"

// //   merkel_balance.balance.withdraw(
// //     t.oracleMintHash,
// //     t.configMintHash,
// //     bRedeemer,
// //     Script(t.merkelBalance),
// //     tx,
// //   )?
// // }

// // test balance_colValueFail() fail {
// //   let inRatio = 1000
// //   let outRatio = 1000

// //   let inLoanAmount = 1000
// //   let inCollateralAmount = 2000
// //   let inCollateralValue = 2000

// //   let outLoanAmount = 1000
// //   let outCollateralAmount = 2000
// //   let outCollateralValue = 500

// //   let test_owner = #"face"

// //   // withdrawl
// //   let withdraw0 = tx.withdrawal(t.merkelBalance)

// //   let bRedeemer = tx.withdrawRedeemer([0])

// //   let loanIn1 = tx.mLoanInput(1, inLoanAmount)
// //   let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue, 0)

// //   let userIn1 = tx.userInput(2024)
// //   let configIn = tx.configInput()
// //   let oracleIn = tx.oracleInput(inRatio)
// //   let oracleOut = tx.oracleOutput(outRatio)

// //   let loanOut1 = tx.mLoanOutput(outLoanAmount)
// //   let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue, 0)

// //   let tx =
// //     Transaction {
// //       ..placeholder,
// //       reference_inputs: [configIn],
// //       extra_signatories: [test_owner],
// //       inputs: [colIn1, loanIn1, oracleIn, userIn1],
// //       outputs: [colOut1, loanOut1, oracleOut],
// //       withdrawals: withdraw0,
// //     }

// //   merkel_balance.balance.withdraw(
// //     t.oracleMintHash,
// //     t.configMintHash,
// //     bRedeemer,
// //     Script(t.merkelBalance),
// //     tx,
// //   )?
// // }

// // test balance_loanAmountFail() fail {
// //   let inRatio = 1000
// //   let outRatio = 1000

// //   let inLoanAmount = 1000
// //   let inCollateralAmount = 2000
// //   let inCollateralValue = 2000

// //   let outLoanAmount = 500
// //   let outCollateralAmount = 1000
// //   let outCollateralValue = 1000

// //   let test_owner = #"face"

// //   // withdrawl
// //   let withdraw0 = tx.withdrawal(t.merkelBalance)

// //   let bRedeemer = tx.withdrawRedeemer([0])

// //   let loanIn1 = tx.mLoanInput(1, inLoanAmount)
// //   let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue, 0)

// //   let userIn1 = tx.userInput(2024)
// //   let configIn = tx.configInput()
// //   let oracleIn = tx.oracleInput(inRatio)
// //   let oracleOut = tx.oracleOutput(outRatio)

// //   let loanOut1 = tx.mLoanOutput(outLoanAmount)
// //   let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue, 0)

// //   let tx =
// //     Transaction {
// //       ..placeholder,
// //       reference_inputs: [configIn],
// //       extra_signatories: [test_owner],
// //       inputs: [colIn1, loanIn1, oracleIn, userIn1],
// //       outputs: [colOut1, loanOut1, oracleOut],
// //       withdrawals: withdraw0,
// //     }

// //   merkel_balance.balance.withdraw(
// //     t.oracleMintHash,
// //     t.configMintHash,
// //     bRedeemer,
// //     Script(t.merkelBalance),
// //     tx,
// //   )?
// // }

// // test balance_tokenSwap() fail {
// //   let inRatio = 1000
// //   let outRatio = 1000

// //   let inLoanAmount = 1000
// //   let inCollateralAmount = 2000
// //   let inCollateralValue = 2000

// //   let outLoanAmount = 1000
// //   let outCollateralAmount = 2000
// //   let outCollateralValue = 4000

// //   let vulnToken = assets.from_asset(t.loanMintHash, #"deaf", 1)

// //   let test_owner = #"face"

// //   // withdrawl
// //   let withdraw0 = tx.withdrawal(t.merkelBalance)

// //   let bRedeemer = tx.withdrawRedeemer([0])

// //   let loanIn1 = tx.mLoanInput(1, inLoanAmount)
// //   let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue, 0)

// //   let userIn1 = tx.userInput(2024)
// //   let configIn = tx.configInput()
// //   let oracleIn = tx.oracleInput(inRatio)
// //   let oracleOut = tx.oracleOutput(outRatio)

// //   let loanOut1 =
// //     t.test_output(
// //       t.test_script_address(t.mLoan),
// //       assets.merge(assets.from_lovelace(2000000), vulnToken),
// //       tx.loanOutDatum(outLoanAmount),
// //     )

// //   let colOut1 =
// //     t.test_output(
// //       t.test_script_address(t.mCol),
// //       assets.merge(assets.from_lovelace(outCollateralValue), vulnToken),
// //       tx.collateralDatumOut(outCollateralAmount, 0),
// //     )

// //   let tx =
// //     Transaction {
// //       ..placeholder,
// //       reference_inputs: [configIn],
// //       extra_signatories: [test_owner],
// //       inputs: [colIn1, loanIn1, oracleIn, userIn1],
// //       outputs: [colOut1, loanOut1, oracleOut],
// //       withdrawals: withdraw0,
// //     }

// //   merkel_balance.balance.withdraw(
// //     t.oracleMintHash,
// //     t.configMintHash,
// //     bRedeemer,
// //     Script(t.merkelBalance),
// //     tx,
// //   )?
// // }

// // test balance_oracleSwap() fail {
// //   let vulnToken = assets.from_asset(t.oracleMintHash, #"1234", 1)

// //   let vulnOracleValue = assets.merge(assets.from_lovelace(2000000), vulnToken)
// //   let inRatio = 1000
// //   let outRatio = 1000

// //   let inLoanAmount = 1000
// //   let inCollateralAmount = 2000
// //   let inCollateralValue = 2000

// //   let outLoanAmount = 1000
// //   let outCollateralAmount = 2000
// //   let outCollateralValue = 4000

// //   let test_owner = #"face"

// //   // withdrawl
// //   let withdraw0 = tx.withdrawal(t.merkelBalance)

// //   let bRedeemer = tx.withdrawRedeemer([0])

// //   let loanIn1 = tx.mLoanInput(1, inLoanAmount)
// //   let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue, 0)

// //   let userIn1 = tx.userInput(2024)
// //   let configIn = tx.configInput()
// //   let oracleIn = tx.oracleInput(inRatio)
// //   let oracleOut =
// //     t.test_output(
// //       t.test_script_address(t.oracleValHash),
// //       vulnOracleValue,
// //       tx.oracleOutDatum(outRatio),
// //     )

// //   let loanOut1 = tx.mLoanOutput(outLoanAmount)
// //   let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue, 0)

// //   let tx =
// //     Transaction {
// //       ..placeholder,
// //       reference_inputs: [configIn],
// //       extra_signatories: [test_owner],
// //       inputs: [colIn1, loanIn1, oracleIn, userIn1],
// //       outputs: [colOut1, loanOut1, oracleOut],
// //       withdrawals: withdraw0,
// //     }

// //   merkel_balance.balance.withdraw(
// //     t.oracleMintHash,
// //     t.configMintHash,
// //     bRedeemer,
// //     Script(t.merkelBalance),
// //     tx,
// //   )?
// // }

// // test balance_ratioFail() fail {
// //   let inRatio = 1000
// //   let outRatio = 900

// //   let inLoanAmount = 1000
// //   let inCollateralAmount = 2000
// //   let inCollateralValue = 2000

// //   let outLoanAmount = 1000
// //   let outCollateralAmount = 2000
// //   let outCollateralValue = 2000

// //   let test_owner = #"face"

// //   // withdrawl
// //   let withdraw0 = tx.withdrawal(t.merkelBalance)

// //   let bRedeemer = tx.withdrawRedeemer([0])

// //   let loanIn1 = tx.mLoanInput(1, inLoanAmount)
// //   let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue, 0)

// //   let userIn1 = tx.userInput(2024)
// //   let configIn = tx.configInput()
// //   let oracleIn = tx.oracleInput(inRatio)
// //   let oracleOut = tx.oracleOutput(outRatio)

// //   let loanOut1 = tx.mLoanOutput(outLoanAmount)
// //   let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue, 0)

// //   let tx =
// //     Transaction {
// //       ..placeholder,
// //       reference_inputs: [configIn],
// //       extra_signatories: [test_owner],
// //       inputs: [colIn1, loanIn1, oracleIn, userIn1],
// //       outputs: [colOut1, loanOut1, oracleOut],
// //       withdrawals: withdraw0,
// //     }

// //   merkel_balance.balance.withdraw(
// //     t.oracleMintHash,
// //     t.configMintHash,
// //     bRedeemer,
// //     Script(t.merkelBalance),
// //     tx,
// //   )?
// // }
