// use cardano/address.{Script}
// use cardano/assets
// use cardano/transaction.{Transaction, placeholder}
// use ref/merkel_liquidate
// use tests/tools as t
// use tests/transactions as tx

// //                             //
// // Liquidation Validator Tests //
// //                             //

// test merkel_liquidate_single() {
//   let inRatio = 200
//   let outRatio = 200

//   let inLoanAmount = 1000
//   let inCollateralAmount = 2000
//   let inCollateralValue = 4000

//   let outLoanAmount = 0
//   let outCollateralAmount = 0
//   let outCollateralValue = 2

//   let test_owner = #"face"

//   // withdrawl
//   let withdraw0 = tx.withdrawal(t.refLiquidate)

//   let loanIn1 = tx.refMLoanInput(1, inLoanAmount)
//   let colIn1 =
//     tx.refMCollateralInput(1, inCollateralAmount, inCollateralValue, 0)

//   let userIn1 = tx.userInput(2024)

//   let configIn = tx.refConfigInput()
//   let oracleIn = tx.refOracleInput(inRatio)
//   let oracleOut = tx.refOracleOutput(outRatio)

//   let loanOut1 = tx.refMLoanOutput(outLoanAmount)
//   let colOut1 =
//     tx.refMCollateralOutput(outCollateralAmount, outCollateralValue, 0)

//   let tx =
//     Transaction {
//       ..placeholder,
//       reference_inputs: [configIn],
//       extra_signatories: [test_owner],
//       inputs: [loanIn1, oracleIn, userIn1, colIn1],
//       outputs: [loanOut1, oracleOut, colOut1],
//       withdrawals: withdraw0,
//     }

//   let redeemerList = tx.withdrawRedeemer([2])

//   merkel_liquidate.liquidate.withdraw(
//     t.refOracleMint,
//     t.refConfigMint,
//     redeemerList,
//     Script(t.refLiquidate),
//     tx,
//   )?
// }
// // test liquidate_loanAmtFail() fail {
// //   let inRatio = 200
// //   let outRatio = 200

// //   let inLoanAmount = 1000
// //   let inCollateralAmount = 2000
// //   let inCollateralValue = 4000

// //   let outLoanAmount = 10
// //   let outCollateralAmount = 0
// //   let outCollateralValue = 2

// //   let test_owner = #"face"

// //   // withdrawl
// //   let withdraw0 = tx.withdrawal(t.merkelLiquidate)

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
// //       inputs: [loanIn1, oracleIn, userIn1, colIn1],
// //       outputs: [loanOut1, oracleOut, colOut1],
// //       withdrawals: withdraw0,
// //     }

// //   let redeemerList = tx.withdrawRedeemer([2])

// //   merkel_liquidate.liquidate.withdraw(
// //     t.oracleMintHash,
// //     t.configMintHash,
// //     redeemerList,
// //     Script(t.merkelLiquidate),
// //     tx,
// //   )?
// // }

// // test liquidate_colAmtFail() fail {
// //   let inRatio = 200
// //   let outRatio = 200

// //   let inLoanAmount = 1000
// //   let inCollateralAmount = 2000
// //   let inCollateralValue = 4000

// //   let outLoanAmount = 0
// //   let outCollateralAmount = 10
// //   let outCollateralValue = 2

// //   let test_owner = #"face"

// //   // withdrawl
// //   let withdraw0 = tx.withdrawal(t.merkelLiquidate)

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
// //       inputs: [loanIn1, oracleIn, userIn1, colIn1],
// //       outputs: [loanOut1, oracleOut, colOut1],
// //       withdrawals: withdraw0,
// //     }

// //   let redeemerList = tx.withdrawRedeemer([2])

// //   merkel_liquidate.liquidate.withdraw(
// //     t.oracleMintHash,
// //     t.configMintHash,
// //     redeemerList,
// //     Script(t.merkelLiquidate),
// //     tx,
// //   )?
// // }

// // test liquidate_tokenSwap() fail {
// //   let inRatio = 200
// //   let outRatio = 200

// //   let inLoanAmount = 1000
// //   let inCollateralAmount = 2000
// //   let inCollateralValue = 4000

// //   let outLoanAmount = 0
// //   let outCollateralAmount = 0
// //   let outCollateralValue = 2

// //   let vulnToken = assets.from_asset(t.loanMintHash, #"deaf", 1)

// //   let test_owner = #"face"

// //   // withdrawl
// //   let withdraw0 = tx.withdrawal(t.merkelLiquidate)

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
// //       inputs: [loanIn1, oracleIn, userIn1, colIn1],
// //       outputs: [loanOut1, oracleOut, colOut1],
// //       withdrawals: withdraw0,
// //     }

// //   let redeemerList = tx.withdrawRedeemer([2])

// //   merkel_liquidate.liquidate.withdraw(
// //     t.oracleMintHash,
// //     t.configMintHash,
// //     redeemerList,
// //     Script(t.merkelLiquidate),
// //     tx,
// //   )?
// // }

// // test liquidate_oracleSwap() fail {
// //   let vulnToken = assets.from_asset(t.oracleMintHash, #"1234", 1)

// //   let vulnOracleValue = assets.merge(assets.from_lovelace(2000000), vulnToken)

// //   let inRatio = 200
// //   let outRatio = 200

// //   let inLoanAmount = 1000
// //   let inCollateralAmount = 2000
// //   let inCollateralValue = 4000

// //   let outLoanAmount = 0
// //   let outCollateralAmount = 0
// //   let outCollateralValue = 2

// //   let test_owner = #"face"

// //   // withdrawl
// //   let withdraw0 = tx.withdrawal(t.merkelLiquidate)

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
// //       inputs: [loanIn1, oracleIn, userIn1, colIn1],
// //       outputs: [loanOut1, oracleOut, colOut1],
// //       withdrawals: withdraw0,
// //     }

// //   let redeemerList = tx.withdrawRedeemer([2])

// //   merkel_liquidate.liquidate.withdraw(
// //     t.oracleMintHash,
// //     t.configMintHash,
// //     redeemerList,
// //     Script(t.merkelLiquidate),
// //     tx,
// //   )?
// // }
