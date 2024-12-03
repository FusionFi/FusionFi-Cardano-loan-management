// use aiken/builtin.{if_then_else}
// use cardano/address.{Script, VerificationKey}
// use cardano/assets
// use cardano/transaction.{Transaction, placeholder}
// use ccfl/interestcalcs.{interestPayment, interestSlope1, interestSlope2}
// use ref/merkel_repay
// use tests/tools as t
// use tests/transactions as tx

// //                       //
// // Repay Validator Tests //
// //                       //

// test repay_interest() {
//   let loanToken = t.refLoanTokenValue()

//   let inRatio = 1000
//   let outRatio = 1000

//   let inLoanAmount = 100
//   let inCollateralAmount = 200
//   let inCollateralValue = 400

//   let outLoanAmount = 0
//   let outCollateralAmount = 0
//   let outCollateralValue = 2

//   let base = 55
//   let optimal = 70
//   let slope1 = 40
//   let slope2 = 300
//   let supply = 1000000
//   let borrowed = 200000
//   let utilisation = 1000000 / 200000

//   let test_owner = #"face"
//   let interestAddr = #"deaf"

//   let inTimestamp = 1721819831
//   let outTimestamp = 1724449574

//   let timeframe = outTimestamp - inTimestamp

//   // trace string.from_int(timeframe)
//   let interest =
//     if_then_else(
//       utilisation <= optimal,
//       interestSlope1(base, optimal, slope1, supply, borrowed),
//       interestSlope2(base, optimal, slope1, slope2, supply, borrowed),
//     )

//   // trace string.from_int(interest)
//   let interestPayment = interestPayment(timeframe, inLoanAmount, interest)

//   // trace string.from_int(interestPayment)
//   let interestExchange = interestPayment / outRatio

//   // withdrawl
//   let withdraw0 = tx.withdrawal(t.refRepay)

//   let bRedeemer = tx.withdrawRedeemer([0])

//   let loanIn1 = tx.refMLoanInput(1, inLoanAmount)
//   let colIn1 =
//     tx.refMCollateralInput(1, inCollateralAmount, inCollateralValue, 0)

//   let userIn1 = tx.userInput(2000000)
//   let configIn = tx.refConfigInput()
//   let interestIn = tx.refInterestInput()
//   let oracleIn = tx.refOracleInput(inRatio)
//   let oracleOut = tx.refOracleOutput(outRatio)

//   let loanOut1 = tx.refMLoanOutput(outLoanAmount)
//   let colOut1 =
//     tx.refMCollateralOutput(outCollateralAmount, outCollateralValue, 0)
//   let interestOut = tx.refInterestOutput(interestExchange)

//   let tx =
//     Transaction {
//       ..placeholder,
//       reference_inputs: [configIn, interestIn],
//       extra_signatories: [test_owner],
//       inputs: [colIn1, loanIn1, oracleIn, userIn1],
//       outputs: [colOut1, loanOut1, oracleOut, interestOut],
//       withdrawals: withdraw0,
//     }

//   merkel_repay.repay.withdraw(
//     interestAddr,
//     t.refOracleMint,
//     t.refConfigMint,
//     bRedeemer,
//     Script(t.refRepay),
//     tx,
//   )?
// }
// // test repay_colAmtFail() fail {
// //   let inRatio = 2
// //   let outRatio = 2

// //   let inLoanAmount = 1000
// //   let inCollateralAmount = 1000
// //   let inCollateralValue = 2000

// //   let outLoanAmount = 500
// //   let outCollateralAmount = 10
// //   let outCollateralValue = 2000

// //   let base = 55
// //   let optimal = 70
// //   let slope1 = 40
// //   let slope2 = 300
// //   let supply = 1000000
// //   let borrowed = 200000
// //   let utilisation = 1000000 / 200000

// //   let test_owner = #"face"
// //   let interestAddr = #"deaf"

// //   let inTimestamp = 1721819831
// //   let outTimestamp = 1724449574

// //   let timeframe = outTimestamp - inTimestamp

// //   // trace string.from_int(timeframe)
// //   let interest =
// //     if_then_else(
// //       utilisation <= optimal,
// //       interestSlope1(base, optimal, slope1, supply, borrowed),
// //       interestSlope2(base, optimal, slope1, slope2, supply, borrowed),
// //     )

// //   // trace string.from_int(interest)
// //   let interestPayment = interestPayment(timeframe, inLoanAmount, interest)

// //   // trace string.from_int(interestPayment)
// //   let interestExchange = interestPayment / outRatio

// //   // withdrawl
// //   let withdraw0 = tx.withdrawal(t.merkelRepay)

// //   let bRedeemer = tx.withdrawRedeemer([0])

// //   let loanIn1 = tx.mLoanInput(1, inLoanAmount)
// //   let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue, 0)

// //   let userIn1 = tx.userInput(2000000)
// //   let configIn = tx.configInput()
// //   let interestIn = tx.interestInput()
// //   let oracleIn = tx.oracleInput(inRatio)
// //   let oracleOut = tx.oracleOutput(outRatio)

// //   let loanOut1 = tx.mLoanOutput(outLoanAmount)
// //   let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue, 0)
// //   let interestOut = tx.interestOutput(interestExchange)

// //   let tx =
// //     Transaction {
// //       ..placeholder,
// //       reference_inputs: [configIn, interestIn],
// //       extra_signatories: [test_owner],
// //       inputs: [colIn1, loanIn1, oracleIn, userIn1],
// //       outputs: [colOut1, loanOut1, oracleOut, interestOut],
// //       withdrawals: withdraw0,
// //     }

// //   merkel_repay.repay.withdraw(
// //     interestAddr,
// //     t.oracleMintHash,
// //     t.configMintHash,
// //     bRedeemer,
// //     VerificationKey(t.merkelRepay),
// //     tx,
// //   )?
// // }

// // test repay_loanAmtFail() fail {
// //   let inRatio = 2
// //   let outRatio = 2

// //   let inLoanAmount = 1000
// //   let inCollateralAmount = 1000
// //   let inCollateralValue = 2000

// //   let outLoanAmount = 1000
// //   let outCollateralAmount = 1000
// //   let outCollateralValue = 2000

// //   let base = 55
// //   let optimal = 70
// //   let slope1 = 40
// //   let slope2 = 300
// //   let supply = 1000000
// //   let borrowed = 200000
// //   let utilisation = 1000000 / 200000

// //   let test_owner = #"face"
// //   let interestAddr = #"deaf"

// //   let inTimestamp = 1721819831
// //   let outTimestamp = 1724449574

// //   let timeframe = outTimestamp - inTimestamp

// //   // trace string.from_int(timeframe)
// //   let interest =
// //     if_then_else(
// //       utilisation <= optimal,
// //       interestSlope1(base, optimal, slope1, supply, borrowed),
// //       interestSlope2(base, optimal, slope1, slope2, supply, borrowed),
// //     )

// //   // trace string.from_int(interest)
// //   let interestPayment = interestPayment(timeframe, inLoanAmount, interest)

// //   // trace string.from_int(interestPayment)
// //   let interestExchange = interestPayment / outRatio

// //   // withdrawl
// //   let withdraw0 = tx.withdrawal(t.merkelRepay)

// //   let bRedeemer = tx.withdrawRedeemer([0])

// //   let loanIn1 = tx.mLoanInput(1, inLoanAmount)
// //   let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue, 0)

// //   let userIn1 = tx.userInput(2000000)
// //   let configIn = tx.configInput()
// //   let interestIn = tx.interestInput()
// //   let oracleIn = tx.oracleInput(inRatio)
// //   let oracleOut = tx.oracleOutput(outRatio)

// //   let loanOut1 = tx.mLoanOutput(outLoanAmount)
// //   let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue, 0)
// //   let interestOut = tx.interestOutput(interestExchange)

// //   let tx =
// //     Transaction {
// //       ..placeholder,
// //       reference_inputs: [configIn, interestIn],
// //       extra_signatories: [test_owner],
// //       inputs: [colIn1, loanIn1, oracleIn, userIn1],
// //       outputs: [colOut1, loanOut1, oracleOut, interestOut],
// //       withdrawals: withdraw0,
// //     }

// //   merkel_repay.repay.withdraw(
// //     interestAddr,
// //     t.oracleMintHash,
// //     t.configMintHash,
// //     bRedeemer,
// //     VerificationKey(t.merkelRepay),
// //     tx,
// //   )?
// // }

// // test repay_tokenSwap() fail {
// //   let vulnToken = assets.from_asset(t.loanMintHash, #"deaf", 1)

// //   let inRatio = 2
// //   let outRatio = 2

// //   let inLoanAmount = 1000
// //   let inCollateralAmount = 1000
// //   let inCollateralValue = 2000

// //   let outLoanAmount = 500
// //   let outCollateralAmount = 1000
// //   let outCollateralValue = 2000

// //   let base = 55
// //   let optimal = 70
// //   let slope1 = 40
// //   let slope2 = 300
// //   let supply = 1000000
// //   let borrowed = 200000
// //   let utilisation = 1000000 / 200000

// //   let test_owner = #"face"
// //   let interestAddr = #"deaf"

// //   let inTimestamp = 1721819831
// //   let outTimestamp = 1724449574

// //   let timeframe = outTimestamp - inTimestamp

// //   // trace string.from_int(timeframe)
// //   let interest =
// //     if_then_else(
// //       utilisation <= optimal,
// //       interestSlope1(base, optimal, slope1, supply, borrowed),
// //       interestSlope2(base, optimal, slope1, slope2, supply, borrowed),
// //     )

// //   // trace string.from_int(interest)
// //   let interestPayment = interestPayment(timeframe, inLoanAmount, interest)

// //   // trace string.from_int(interestPayment)
// //   let interestExchange = interestPayment / outRatio

// //   // withdrawl
// //   let withdraw0 = tx.withdrawal(t.merkelRepay)

// //   let bRedeemer = tx.withdrawRedeemer([0])

// //   let loanIn1 = tx.mLoanInput(1, inLoanAmount)
// //   let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue, 0)

// //   let userIn1 = tx.userInput(2000000)
// //   let configIn = tx.configInput()
// //   let interestIn = tx.interestInput()
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

// //   let interestOut = tx.interestOutput(interestExchange)

// //   let tx =
// //     Transaction {
// //       ..placeholder,
// //       reference_inputs: [configIn, interestIn],
// //       extra_signatories: [test_owner],
// //       inputs: [colIn1, loanIn1, oracleIn, userIn1],
// //       outputs: [colOut1, loanOut1, oracleOut, interestOut],
// //       withdrawals: withdraw0,
// //     }

// //   merkel_repay.repay.withdraw(
// //     interestAddr,
// //     t.oracleMintHash,
// //     t.configMintHash,
// //     bRedeemer,
// //     VerificationKey(t.merkelRepay),
// //     tx,
// //   )?
// // }

// // test repay_oracleSwap() fail {
// //   let vulnToken = assets.from_asset(t.oracleMintHash, #"1234", 1)

// //   let vulnOracleValue = assets.merge(assets.from_lovelace(2000000), vulnToken)

// //   let inRatio = 2
// //   let outRatio = 2

// //   let inLoanAmount = 1000
// //   let inCollateralAmount = 1000
// //   let inCollateralValue = 2000

// //   let outLoanAmount = 500
// //   let outCollateralAmount = 1000
// //   let outCollateralValue = 2000

// //   let base = 55
// //   let optimal = 70
// //   let slope1 = 40
// //   let slope2 = 300
// //   let supply = 1000000
// //   let borrowed = 200000
// //   let utilisation = 1000000 / 200000

// //   let test_owner = #"face"

// //   let interestAddr = #"deaf"

// //   let inTimestamp = 1721819831
// //   let outTimestamp = 1724449574

// //   let timeframe = outTimestamp - inTimestamp

// //   // trace string.from_int(timeframe)
// //   let interest =
// //     if_then_else(
// //       utilisation <= optimal,
// //       interestSlope1(base, optimal, slope1, supply, borrowed),
// //       interestSlope2(base, optimal, slope1, slope2, supply, borrowed),
// //     )

// //   // trace string.from_int(interest)
// //   let interestPayment = interestPayment(timeframe, inLoanAmount, interest)

// //   // trace string.from_int(interestPayment)
// //   let interestExchange = interestPayment / outRatio

// //   // withdrawl
// //   let withdraw0 = tx.withdrawal(t.merkelRepay)

// //   let bRedeemer = tx.withdrawRedeemer([0])

// //   let loanIn1 = tx.mLoanInput(1, inLoanAmount)
// //   let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue, 0)

// //   let userIn1 = tx.userInput(2000000)
// //   let configIn = tx.configInput()
// //   let interestIn = tx.interestInput()
// //   let oracleIn = tx.oracleInput(inRatio)
// //   let oracleOut =
// //     t.test_output(
// //       t.test_script_address(t.oracleValHash),
// //       vulnOracleValue,
// //       tx.oracleOutDatum(outRatio),
// //     )

// //   let loanOut1 = tx.mLoanOutput(outLoanAmount)
// //   let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue, 0)
// //   let interestOut = tx.interestOutput(interestExchange)

// //   let tx =
// //     Transaction {
// //       ..placeholder,
// //       reference_inputs: [configIn, interestIn],
// //       extra_signatories: [test_owner],
// //       inputs: [colIn1, loanIn1, oracleIn, userIn1],
// //       outputs: [colOut1, loanOut1, oracleOut, interestOut],
// //       withdrawals: withdraw0,
// //     }

// //   merkel_repay.repay.withdraw(
// //     interestAddr,
// //     t.oracleMintHash,
// //     t.configMintHash,
// //     bRedeemer,
// //     VerificationKey(t.merkelRepay),
// //     tx,
// //   )?
// // }

// // test repay_multi() {
// //   let inRatio = 1000
// //   let outRatio = 1000

// //   let loanToken1 = assets.from_asset(t.loanMintHash, #"aced", 1)
// //   let loanToken2 = assets.from_asset(t.loanMintHash, #"beef", 1)
// //   let loanToken3 = assets.from_asset(t.loanMintHash, #"ceed", 1)

// //   let inLoanAmount1 = 1000
// //   let inCollateralAmount1 = 1000
// //   let inCollateralValue1 = 2000

// //   let outLoanAmount1 = 1000
// //   let outCollateralAmount1 = 2000
// //   let outCollateralValue1 = 2000

// //   let inLoanAmount2 = 1000
// //   let inCollateralAmount2 = 2000
// //   let inCollateralValue2 = 4000

// //   let outLoanAmount2 = 500
// //   let outCollateralAmount2 = 1000
// //   let outCollateralValue2 = 4000

// //   let inLoanAmount3 = 500
// //   let inCollateralAmount3 = 1000
// //   let inCollateralValue3 = 2000

// //   let outLoanAmount3 = 500
// //   let outCollateralAmount3 = 1000
// //   let outCollateralValue3 = 2000

// //   let base = 55
// //   let optimal = 70
// //   let slope1 = 40
// //   let slope2 = 300
// //   let supply = 1000000
// //   let borrowed = 200000
// //   let utilisation = 1000000 / 200000

// //   let test_owner = #"face"
// //   let interestAddr = #"deaf"

// //   let inTimestamp = 1721819831
// //   let outTimestamp = 1724449574

// //   let timeframe = outTimestamp - inTimestamp

// //   // trace string.from_int(timeframe)
// //   let interest =
// //     if_then_else(
// //       utilisation <= optimal,
// //       interestSlope1(base, optimal, slope1, supply, borrowed),
// //       interestSlope2(base, optimal, slope1, slope2, supply, borrowed),
// //     )

// //   // trace string.from_int(interest)
// //   let interestPayment1 = interestPayment(timeframe, inLoanAmount1, interest)
// //   let interestPayment2 = interestPayment(timeframe, inLoanAmount2, interest)
// //   let interestPayment3 = interestPayment(timeframe, inLoanAmount3, interest)

// //   let interestExchange1 = interestPayment1 / outRatio
// //   let interestExchange2 = interestPayment2 / outRatio
// //   let interestExchange3 = interestPayment3 / outRatio

// //   // trace string.from_int(interestExchange1)
// //   // withdrawl
// //   let withdraw0 = tx.withdrawal(t.merkelRepay)

// //   let bRedeemer = tx.withdrawRedeemer([0])

// //   let loanIn1 = tx.mLoanIn(1, inLoanAmount1, loanToken1)
// //   let colIn1 =
// //     tx.mColIn(1, inCollateralAmount1, inCollateralValue1, loanToken1, 0)
// //   let loanIn2 = tx.mLoanIn(2, inLoanAmount2, loanToken2)
// //   let colIn2 =
// //     tx.mColIn(2, inCollateralAmount2, inCollateralValue2, loanToken2, 0)
// //   let loanIn3 = tx.mLoanIn(3, inLoanAmount3, loanToken3)
// //   let colIn3 =
// //     tx.mColIn(3, inCollateralAmount3, inCollateralValue3, loanToken3, 0)

// //   let userIn1 = tx.userInput(2000)
// //   let configIn = tx.configInput()
// //   let interestIn = tx.interestInput()
// //   let oracleIn = tx.oracleInput(inRatio)
// //   let oracleOut = tx.oracleOutput(outRatio)

// //   let loanOut1 = tx.mLoanOut(outLoanAmount1, loanToken1)
// //   let colOut1 =
// //     tx.mColOut(outCollateralAmount1, outCollateralValue1, loanToken1, 0)
// //   let interestOut1 = tx.interestOutput(interestExchange1)
// //   let loanOut2 = tx.mLoanOut(outLoanAmount2, loanToken2)
// //   let colOut2 =
// //     tx.mColOut(outCollateralAmount2, outCollateralValue2, loanToken2, 0)
// //   let interestOut2 = tx.interestOutput(interestExchange2)
// //   let loanOut3 = tx.mLoanOut(outLoanAmount3, loanToken3)
// //   let colOut3 =
// //     tx.mColOut(outCollateralAmount3, outCollateralValue3, loanToken3, 0)
// //   let interestOut3 = tx.interestOutput(interestExchange3)

// //   let tx =
// //     Transaction {
// //       ..placeholder,
// //       reference_inputs: [configIn, interestIn],
// //       extra_signatories: [test_owner],
// //       inputs: [
// //         colIn1, loanIn1, colIn2, loanIn2, colIn3, loanIn3, oracleIn, userIn1,
// //       ],
// //       outputs: [
// //         colOut1, loanOut1, colOut2, loanOut2, colOut3, loanOut3, oracleOut,
// //         interestOut1, interestOut2, interestOut3,
// //       ],
// //       withdrawals: withdraw0,
// //     }

// //   merkel_repay.repay.withdraw(
// //     interestAddr,
// //     t.oracleMintHash,
// //     t.configMintHash,
// //     bRedeemer,
// //     VerificationKey(t.merkelRepay),
// //     tx,
// //   )?
// // }
