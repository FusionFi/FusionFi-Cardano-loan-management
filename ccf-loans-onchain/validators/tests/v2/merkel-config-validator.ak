// use cardano/assets
// use cardano/transaction.{InlineDatum, Transaction, placeholder}
// use ref/config
// use tests/tools as t
// // use tests/tools as t
// use tests/transactions as tx

// // use tests/transactions.{configActionUpdate, configDatum, oracleDatum}

// //                        //
// // Config Validator Tests //
// //                        //

// test config_val() {
//   let test_owner = #"face"

//   let oref = tx.oref(#"cece", 1)

//   let configAction =
//     tx.mConUpdate(
//       t.refLoanSpend,
//       t.refCollateralSpend,
//       t.refRewardsMint,
//       t.refOracleMint,
//       t.refInterestSpend,
//       t.refCollateralRedeemers(),
//     )

//   let configDatum =
//     tx.mConfigDatum(
//       t.refLoanSpend,
//       t.refCollateralSpend,
//       t.refRewardsMint,
//       t.refOracleMint,
//       t.refInterestSpend,
//       #"bebe",
//       t.refCollateralRedeemers(),
//     )

//   let configInput = tx.refConfigInput()

//   let configOutput = tx.refConfigOutput(configDatum)

//   let tx =
//     Transaction {
//       ..placeholder,
//       extra_signatories: [test_owner],
//       inputs: [configInput],
//       outputs: [configOutput],
//     }

//   config.config.spend(test_owner, Some(configDatum), configAction, oref, tx)?
// }
// // test config_tokenSwap() {
// //   let vulnToken = assets.from_asset(t.configMintHash, #"1234", 1)

// //   let vulnOutputValue = assets.merge(assets.from_lovelace(2000000), vulnToken)

// //   let test_owner = #"face"

// //   let oref = tx.oref(#"cece", 1)

// //   let configAction =
// //     tx.mConUpdate(
// //       t.mLoan,
// //       t.mCol,
// //       t.rewardsMintHash,
// //       t.oracleValHash,
// //       t.interestValHash,
// //       t.collateralRedeemers(),
// //     )

// //   let configDatum =
// //     tx.mConfigDatum(
// //       t.mLoan,
// //       t.mCol,
// //       t.rewardsMintHash,
// //       t.oracleValHash,
// //       t.interestValHash,
// //       #"bebe",
// //       t.collateralRedeemers(),
// //     )

// //   let configInput = tx.configInput()

// //   let configOutput =
// //     t.test_output(
// //       t.test_script_address(t.merkelConfigHash),
// //       vulnOutputValue,
// //       InlineDatum(configDatum),
// //     )

// //   let tx =
// //     Transaction {
// //       ..placeholder,
// //       extra_signatories: [test_owner],
// //       inputs: [configInput],
// //       outputs: [configOutput],
// //     }

// //   trace @"VULNERABILITY"
// //   trace @"We can swap out configTokens with different names"
// //   config.config.spend(test_owner, Some(configDatum), configAction, oref, tx)?
// // }

// // test config_sigFail() fail {
// //   let test_owner = #"face"

// //   let oref = tx.oref(#"cece", 1)

// //   let configAction =
// //     tx.mConUpdate(
// //       t.mLoan,
// //       t.mCol,
// //       t.rewardsMintHash,
// //       t.oracleValHash,
// //       t.interestValHash,
// //       t.collateralRedeemers(),
// //     )

// //   let configDatum =
// //     tx.mConfigDatum(
// //       t.mLoan,
// //       t.mCol,
// //       t.rewardsMintHash,
// //       t.oracleValHash,
// //       t.interestValHash,
// //       #"bebe",
// //       t.collateralRedeemers(),
// //     )

// //   let configInput = tx.configInput()

// //   let configOutput = tx.configOutput(configDatum)

// //   let tx =
// //     Transaction {
// //       ..placeholder,
// //       extra_signatories: [#"dede"],
// //       inputs: [configInput],
// //       outputs: [configOutput],
// //     }

// //   config.config.spend(test_owner, Some(configDatum), configAction, oref, tx)?
// // }
