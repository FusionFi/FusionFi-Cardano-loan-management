// use cardano/assets
// use cardano/transaction.{InlineDatum, NoDatum, Transaction, placeholder}
// use ref/config
// use tests/tools as t
// use tests/transactions.{mConUpdate, mConfigDatum, oracleDatumIn}

// //                      //
// // Config Minting Tests //
// //                      //

// test config_mint() {
//   let test_owner = #"face"

//   let oref = t.test_oref(#"face", 1)

//   let configAction =
//     mConUpdate(
//       t.refLoanSpend,
//       t.refCollateralSpend,
//       t.refRewardsMint,
//       t.refOracleSpend,
//       t.refInterestSpend,
//       t.refCollateralRedeemers(),
//     )

//   let configDatum1 =
//     mConfigDatum(
//       t.refLoanSpend,
//       t.refCollateralSpend,
//       t.refRewardsMint,
//       t.refOracleSpend,
//       t.refInterestSpend,
//       #"bebe",
//       t.refCollateralRedeemers(),
//     )

//   let outDatum = InlineDatum(configDatum1)

//   let ownerInput =
//     t.test_input(
//       oref,
//       t.test_output(t.test_address(test_owner), t.makeAdaValue(10), NoDatum),
//     )

//   let configOutput =
//     t.test_output(
//       t.test_script_address(t.refConfigSpend),
//       t.refConfigValue(),
//       outDatum,
//     )

//   let tx =
//     Transaction {
//       ..placeholder,
//       mint: t.refConfigMintedValue(),
//       extra_signatories: [test_owner],
//       inputs: [ownerInput],
//       outputs: [configOutput],
//     }

//   config.config.mint(test_owner, configAction, t.refConfigMint, tx)?
// }
// // test config_mint_qty_fail() fail {
// //   let test_owner = #"face"

// //   let mintValue = assets.merge(t.configTokenValue(), t.configTokenValue())

// //   let oref = t.test_oref(#"face", 1)

// //   let configAction =
// //     mConUpdate(
// //       t.loanValHash,
// //       t.collateralValHash,
// //       t.rewardsMintHash,
// //       t.oracleValHash,
// //       t.interestValHash,
// //       t.collateralRedeemers(),
// //     )

// //   let configDatum1 =
// //     mConfigDatum(
// //       t.loanValHash,
// //       t.collateralValHash,
// //       t.rewardsMintHash,
// //       t.oracleValHash,
// //       t.interestValHash,
// //       #"bebe",
// //       t.collateralRedeemers(),
// //     )

// //   let outDatum = InlineDatum(configDatum1)

// //   let ownerInput =
// //     t.test_input(
// //       oref,
// //       t.test_output(t.test_address(test_owner), t.makeAdaValue(10), NoDatum),
// //     )

// //   let configOutput =
// //     t.test_output(
// //       t.test_script_address(t.configValHash),
// //       t.configValue(),
// //       outDatum,
// //     )

// //   let tx =
// //     Transaction {
// //       ..placeholder,
// //       mint: mintValue,
// //       extra_signatories: [test_owner],
// //       inputs: [ownerInput],
// //       outputs: [configOutput],
// //     }

// //   config.config.mint(test_owner, configAction, t.configMintHash, tx)?
// // }

// // test config_mint_datum_fail() fail {
// //   let test_owner = #"face"

// //   let oref = t.test_oref(#"face", 1)

// //   let configAction =
// //     mConUpdate(
// //       t.loanValHash,
// //       t.collateralValHash,
// //       t.rewardsMintHash,
// //       t.oracleValHash,
// //       t.interestValHash,
// //       t.collateralRedeemers(),
// //     )

// //   // let configDatum1 = oracleDatumIn
// //   let outDatum = oracleDatumIn(1)

// //   let ownerInput =
// //     t.test_input(
// //       oref,
// //       t.test_output(t.test_address(test_owner), t.makeAdaValue(10), NoDatum),
// //     )

// //   let configOutput =
// //     t.test_output(
// //       t.test_script_address(t.configValHash),
// //       t.configValue(),
// //       outDatum,
// //     )

// //   let tx =
// //     Transaction {
// //       ..placeholder,
// //       mint: t.configMintedValue(),
// //       extra_signatories: [test_owner],
// //       inputs: [ownerInput],
// //       outputs: [configOutput],
// //     }

// //   config.config.mint(test_owner, configAction, t.configMintHash, tx)?
// // }

// // test config_mint_sigs_fail() fail {
// //   let test_owner = #"face"

// //   let oref = t.test_oref(#"face", 1)

// //   let configAction =
// //     mConUpdate(
// //       t.loanValHash,
// //       t.collateralValHash,
// //       t.rewardsMintHash,
// //       t.oracleValHash,
// //       t.interestValHash,
// //       t.collateralRedeemers(),
// //     )

// //   let configDatum1 =
// //     mConfigDatum(
// //       t.loanValHash,
// //       t.collateralValHash,
// //       t.rewardsMintHash,
// //       t.oracleValHash,
// //       t.interestValHash,
// //       #"bebe",
// //       t.collateralRedeemers(),
// //     )
// //   let outDatum = InlineDatum(configDatum1)

// //   let ownerInput =
// //     t.test_input(
// //       oref,
// //       t.test_output(t.test_address(test_owner), t.makeAdaValue(10), NoDatum),
// //     )

// //   let configOutput =
// //     t.test_output(
// //       t.test_script_address(t.configValHash),
// //       t.configValue(),
// //       outDatum,
// //     )

// //   let tx =
// //     Transaction {
// //       ..placeholder,
// //       mint: t.configMintedValue(),
// //       extra_signatories: [#"cafe"],
// //       inputs: [ownerInput],
// //       outputs: [configOutput],
// //     }

// //   config.config.mint(test_owner, configAction, t.configMintHash, tx)?
// // }

// // test multi_mint_names_fail() fail {
// //   let test_owner = #"face"
// //   let vulnValue = assets.from_asset(t.configMintHash, #"cece", 1)

// //   let mintValue = assets.merge(t.configTokenValue(), vulnValue)

// //   let oref = t.test_oref(#"face", 1)

// //   let configAction =
// //     mConUpdate(
// //       t.loanValHash,
// //       t.collateralValHash,
// //       t.rewardsMintHash,
// //       t.oracleValHash,
// //       t.interestValHash,
// //       t.collateralRedeemers(),
// //     )

// //   let configDatum1 =
// //     mConfigDatum(
// //       t.loanValHash,
// //       t.collateralValHash,
// //       t.rewardsMintHash,
// //       t.oracleValHash,
// //       t.interestValHash,
// //       #"bebe",
// //       t.collateralRedeemers(),
// //     )

// //   let outDatum = InlineDatum(configDatum1)

// //   let ownerInput =
// //     t.test_input(
// //       oref,
// //       t.test_output(t.test_address(test_owner), t.makeAdaValue(10), NoDatum),
// //     )

// //   let configOutput =
// //     t.test_output(
// //       t.test_script_address(t.configValHash),
// //       t.configValue(),
// //       outDatum,
// //     )

// //   // let vulnOut = t.test_output(t.test_address(test_owner), vulnValue, outDatum)
// //   let tx =
// //     Transaction {
// //       ..placeholder,
// //       mint: mintValue,
// //       extra_signatories: [test_owner],
// //       inputs: [ownerInput],
// //       outputs: [configOutput],
// //     }

// //   config.config.mint(test_owner, configAction, t.configMintHash, tx)?
// // }

// // test config_any_output() {
// //   let test_owner = #"face"

// //   let oref = t.test_oref(#"face", 1)

// //   let configAction =
// //     mConUpdate(
// //       t.loanValHash,
// //       t.collateralValHash,
// //       t.rewardsMintHash,
// //       t.oracleValHash,
// //       t.interestValHash,
// //       t.collateralRedeemers(),
// //     )

// //   let configDatum1 =
// //     mConfigDatum(
// //       t.loanValHash,
// //       t.collateralValHash,
// //       t.rewardsMintHash,
// //       t.oracleValHash,
// //       t.interestValHash,
// //       #"bebe",
// //       t.collateralRedeemers(),
// //     )

// //   let outDatum = InlineDatum(configDatum1)

// //   let ownerInput =
// //     t.test_input(
// //       oref,
// //       t.test_output(t.test_address(test_owner), t.makeAdaValue(10), NoDatum),
// //     )

// //   let configOutput =
// //     t.test_output(
// //       t.test_script_address(t.loanValHash),
// //       t.configValue(),
// //       outDatum,
// //     )

// //   let tx =
// //     Transaction {
// //       ..placeholder,
// //       mint: t.configMintedValue(),
// //       extra_signatories: [test_owner],
// //       inputs: [ownerInput],
// //       outputs: [configOutput],
// //     }

// //   config.config.mint(test_owner, configAction, t.configMintHash, tx)?
// // }
