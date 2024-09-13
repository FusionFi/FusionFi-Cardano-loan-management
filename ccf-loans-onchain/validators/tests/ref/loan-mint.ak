// use cardano/assets
// use cardano/transaction.{InlineDatum, NoDatum, Transaction, placeholder}
// use ref/loan_mint
// use tests/tools as t
// use tests/transactions as tx

// //                 //
// // Loan Mint Tests //
// //                 //

// test loan_mint() {
//   let test_owner = #"face"

//   let oref = t.test_oref(#"face", 1)
//   let cref = t.test_oref(#"cafe", 2)
//   let rref = t.test_oref(#"dead", 6)

//   let mintAction = tx.loanMintActionMint(1000, 12, 1111111114)

//   let loanMintedValue =
//     assets.merge(t.refLoanTokenValue(), t.refLoanTokenValue())

//   let configInDatum = tx.refConfigDatumIn()

//   let loanDatum = tx.loanDatum(1000, 0, 12, 1111111114, #"beef")
//   let loanOutDatum = InlineDatum(loanDatum)
//   let loanOutValue = t.refLoanTokenValue()

//   let collateralDatum = tx.collateralDatum(2000, 11111114, 0)
//   let colDatumOut = InlineDatum(collateralDatum)
//   let colOutValue = assets.merge(t.makeAdaValue(2002), t.refLoanTokenValue())

//   let oracleInDatum = tx.oracleDatum(1000, 11111112, 1000000, 200000, "USD")
//   let oracleOutDatum = tx.oracleDatum(1000, 11111114, 1000000, 200000, "USD")
//   let oInDatum = InlineDatum(oracleInDatum)
//   let oOutDatum = InlineDatum(oracleOutDatum)

//   let noDatum = NoDatum

//   let userIn =
//     t.test_input(
//       oref,
//       t.test_output(t.test_address(#"cafe"), t.makeAdaValue(2010), noDatum),
//     )

//   let configIn =
//     t.test_input(
//       cref,
//       t.test_output(
//         t.test_script_address(t.refConfigSpend),
//         t.refConfigValue(),
//         configInDatum,
//       ),
//     )

//   let oracleIn =
//     t.test_input(
//       rref,
//       t.test_output(
//         t.test_script_address(t.refOracleSpend),
//         t.refOracleValue(),
//         oInDatum,
//       ),
//     )

//   let oracleOut =
//     t.test_output(
//       t.test_script_address(t.refOracleSpend),
//       t.refOracleValue(),
//       oOutDatum,
//     )

//   let loanOut =
//     t.test_output(
//       t.test_script_address(t.refLoanSpend),
//       loanOutValue,
//       loanOutDatum,
//     )

//   let colOut =
//     t.test_output(
//       t.test_script_address(t.refCollateralSpend),
//       colOutValue,
//       colDatumOut,
//     )

//   let tx =
//     Transaction {
//       ..placeholder,
//       reference_inputs: [configIn],
//       mint: loanMintedValue,
//       extra_signatories: [test_owner],
//       inputs: [userIn, oracleIn],
//       outputs: [loanOut, colOut, oracleOut],
//     }

//   loan_mint.loanMint.mint(
//     t.refOracleMint,
//     t.refConfigMint,
//     mintAction,
//     t.refLoanMint,
//     tx,
//   )?
// }
// // test mint_loanDatumFail() fail {
// //   let test_owner = #"face"

// //   let oref = t.test_oref(#"face", 1)
// //   let cref = t.test_oref(#"cafe", 2)
// //   let rref = t.test_oref(#"dead", 6)

// //   let mintAction = loanMintActionMint(1000, 12, 1111111114)

// //   let loanMintedValue = assets.merge(t.loanTokenValue(), t.loanTokenValue())

// //   let configInDatum = configDatumIn()

// //   let loanDatum = loanDatum(500, 0, 12, 1111111114, #"beef")
// //   let loanOutDatum = InlineDatum(loanDatum)
// //   let loanOutValue = t.loanTokenValue()

// //   let collateralDatum = collateralDatum(2000, 12, 0)
// //   let colOutDatum = InlineDatum(collateralDatum)
// //   let colOutValue = assets.merge(t.makeAdaValue(2002), t.loanTokenValue())

// //   let oracleInDatum = oracleDatum(2000, 11111112, 1000000, 200000, "USD")
// //   let oracleOutDatum = oracleDatum(1000, 11111114, 1000000, 200000, "USD")
// //   let oInDatum = InlineDatum(oracleInDatum)
// //   let oOutDatum = InlineDatum(oracleOutDatum)

// //   let noDatum = NoDatum

// //   let userIn =
// //     t.test_input(
// //       oref,
// //       t.test_output(t.test_address(#"cafe"), t.makeAdaValue(2010), noDatum),
// //     )

// //   let configIn =
// //     t.test_input(
// //       cref,
// //       t.test_output(
// //         t.test_script_address(t.configValHash),
// //         t.configValue(),
// //         configInDatum,
// //       ),
// //     )

// //   let oracleIn =
// //     t.test_input(
// //       rref,
// //       t.test_output(
// //         t.test_script_address(t.oracleValHash),
// //         t.oracleValue(),
// //         oInDatum,
// //       ),
// //     )

// //   let oracleOut =
// //     t.test_output(
// //       t.test_script_address(t.oracleValHash),
// //       t.oracleValue(),
// //       oOutDatum,
// //     )

// //   let loanOut =
// //     t.test_output(
// //       t.test_script_address(t.merkelLoanSpend),
// //       loanOutValue,
// //       loanOutDatum,
// //     )

// //   let colOut =
// //     t.test_output(
// //       t.test_script_address(t.merkelCollateralSpend),
// //       colOutValue,
// //       colOutDatum,
// //     )

// //   let tx =
// //     Transaction {
// //       ..placeholder,
// //       reference_inputs: [configIn],
// //       mint: loanMintedValue,
// //       extra_signatories: [test_owner],
// //       inputs: [userIn, oracleIn],
// //       outputs: [loanOut, colOut, oracleOut],
// //     }

// //   loan_mint.loanMint.mint(
// //     t.oracleMintHash,
// //     t.configMintHash,
// //     mintAction,
// //     t.loanMintHash,
// //     tx,
// //   )
// // }

// // test mint_colDatumFail() fail {
// //   let test_owner = #"face"

// //   let oref = t.test_oref(#"face", 1)
// //   let cref = t.test_oref(#"cafe", 2)
// //   let rref = t.test_oref(#"dead", 6)

// //   let mintAction = loanMintActionMint(1000, 12, 1111111114)

// //   let loanMintedValue = assets.merge(t.loanTokenValue(), t.loanTokenValue())

// //   let configInDatum = configDatumIn()

// //   let loanDatum = loanDatum(1000, 0, 12, 1111111114, #"beef")
// //   let loanOutDatum = InlineDatum(loanDatum)
// //   let loanOutValue = t.loanTokenValue()

// //   let collateralDatum = collateralDatum(1000, 12, 0)
// //   let colOutDatum = InlineDatum(collateralDatum)
// //   let colOutValue = assets.merge(t.makeAdaValue(2002), t.loanTokenValue())

// //   let oracleInDatum = oracleDatum(2000, 11111112, 1000000, 200000, "USD")
// //   let oracleOutDatum = oracleDatum(1000, 11111114, 1000000, 200000, "USD")
// //   let oInDatum = InlineDatum(oracleInDatum)
// //   let oOutDatum = InlineDatum(oracleOutDatum)

// //   let noDatum = NoDatum

// //   let userIn =
// //     t.test_input(
// //       oref,
// //       t.test_output(t.test_address(#"cafe"), t.makeAdaValue(2010), noDatum),
// //     )

// //   let configIn =
// //     t.test_input(
// //       cref,
// //       t.test_output(
// //         t.test_script_address(t.configValHash),
// //         t.configValue(),
// //         configInDatum,
// //       ),
// //     )

// //   let oracleIn =
// //     t.test_input(
// //       rref,
// //       t.test_output(
// //         t.test_script_address(t.oracleValHash),
// //         t.oracleValue(),
// //         oInDatum,
// //       ),
// //     )

// //   let oracleOut =
// //     t.test_output(
// //       t.test_script_address(t.oracleValHash),
// //       t.oracleValue(),
// //       oOutDatum,
// //     )

// //   let loanOut =
// //     t.test_output(
// //       t.test_script_address(t.merkelLoanSpend),
// //       loanOutValue,
// //       loanOutDatum,
// //     )

// //   let colOut =
// //     t.test_output(
// //       t.test_script_address(t.merkelCollateralSpend),
// //       colOutValue,
// //       colOutDatum,
// //     )

// //   let tx =
// //     Transaction {
// //       ..placeholder,
// //       reference_inputs: [configIn],
// //       mint: loanMintedValue,
// //       extra_signatories: [test_owner],
// //       inputs: [userIn, oracleIn],
// //       outputs: [loanOut, colOut, oracleOut],
// //     }

// //   loan_mint.loanMint.mint(
// //     t.oracleMintHash,
// //     t.configMintHash,
// //     mintAction,
// //     t.loanMintHash,
// //     tx,
// //   )
// // }

// // test mint_actionFail() fail {
// //   let test_owner = #"face"

// //   let oref = t.test_oref(#"face", 1)
// //   let cref = t.test_oref(#"cafe", 2)
// //   let rref = t.test_oref(#"dead", 6)

// //   let mintAction = loanMintActionMint(500, 12, 1111111114)

// //   let loanMintedValue = assets.merge(t.loanTokenValue(), t.loanTokenValue())

// //   let configInDatum = configDatumIn()

// //   let loanDatum = loanDatum(1000, 0, 12, 1111111114, #"beef")
// //   let loanOutDatum = InlineDatum(loanDatum)
// //   let loanOutValue = t.loanTokenValue()

// //   let collateralDatum = collateralDatum(2000, 12, 0)
// //   let colOutDatum = InlineDatum(collateralDatum)
// //   let colOutValue = assets.merge(t.makeAdaValue(2002), t.loanTokenValue())

// //   let oracleInDatum = oracleDatum(2000, 11111112, 1000000, 200000, "USD")
// //   let oracleOutDatum = oracleDatum(1000, 11111114, 1000000, 200000, "USD")
// //   let oInDatum = InlineDatum(oracleInDatum)
// //   let oOutDatum = InlineDatum(oracleOutDatum)

// //   let noDatum = NoDatum

// //   let userIn =
// //     t.test_input(
// //       oref,
// //       t.test_output(t.test_address(#"cafe"), t.makeAdaValue(2010), noDatum),
// //     )

// //   let configIn =
// //     t.test_input(
// //       cref,
// //       t.test_output(
// //         t.test_script_address(t.configValHash),
// //         t.configValue(),
// //         configInDatum,
// //       ),
// //     )

// //   let oracleIn =
// //     t.test_input(
// //       rref,
// //       t.test_output(
// //         t.test_script_address(t.oracleValHash),
// //         t.oracleValue(),
// //         oInDatum,
// //       ),
// //     )

// //   let oracleOut =
// //     t.test_output(
// //       t.test_script_address(t.oracleValHash),
// //       t.oracleValue(),
// //       oOutDatum,
// //     )

// //   let loanOut =
// //     t.test_output(
// //       t.test_script_address(t.merkelLoanSpend),
// //       loanOutValue,
// //       loanOutDatum,
// //     )

// //   let colOut =
// //     t.test_output(
// //       t.test_script_address(t.merkelCollateralSpend),
// //       colOutValue,
// //       colOutDatum,
// //     )

// //   let tx =
// //     Transaction {
// //       ..placeholder,
// //       reference_inputs: [configIn],
// //       mint: loanMintedValue,
// //       extra_signatories: [test_owner],
// //       inputs: [userIn, oracleIn],
// //       outputs: [loanOut, colOut, oracleOut],
// //     }

// //   loan_mint.loanMint.mint(
// //     t.oracleMintHash,
// //     t.configMintHash,
// //     mintAction,
// //     t.loanMintHash,
// //     tx,
// //   )
// // }

// // test mint_oracleFail() fail {
// //   let test_owner = #"face"

// //   let oref = t.test_oref(#"face", 1)
// //   let cref = t.test_oref(#"cafe", 2)
// //   let rref = t.test_oref(#"dead", 6)

// //   let mintAction = loanMintActionMint(1000, 12, 1111111114)

// //   let loanMintedValue = assets.merge(t.loanTokenValue(), t.loanTokenValue())

// //   let configInDatum = configDatumIn()

// //   let loanDatum = loanDatum(1000, 0, 12, 1111111114, #"beef")
// //   let loanOutDatum = InlineDatum(loanDatum)
// //   let loanOutValue = t.loanTokenValue()

// //   let collateralDatum = collateralDatum(2000, 12, 0)
// //   let colOutDatum = InlineDatum(collateralDatum)
// //   let colOutValue = assets.merge(t.makeAdaValue(2002), t.loanTokenValue())

// //   let oracleInDatum = oracleDatum(2000, 11111112, 1000000, 200000, "USD")
// //   let oracleOutDatum = oracleDatum(1000, 11111114, 1000000, 200000, "USD")
// //   let oInDatum = InlineDatum(oracleInDatum)
// //   let oOutDatum = InlineDatum(oracleOutDatum)

// //   let noDatum = NoDatum

// //   let userIn =
// //     t.test_input(
// //       oref,
// //       t.test_output(t.test_address(#"cafe"), t.makeAdaValue(2010), noDatum),
// //     )

// //   let configIn =
// //     t.test_input(
// //       cref,
// //       t.test_output(
// //         t.test_script_address(t.configValHash),
// //         t.configValue(),
// //         configInDatum,
// //       ),
// //     )

// //   let oracleIn =
// //     t.test_input(
// //       rref,
// //       t.test_output(
// //         t.test_script_address(t.oracleValHash),
// //         t.oracleValue(),
// //         oInDatum,
// //       ),
// //     )

// //   let oracleOut =
// //     t.test_output(
// //       t.test_script_address(t.oracleValHash),
// //       t.configValue(),
// //       oOutDatum,
// //     )

// //   let loanOut =
// //     t.test_output(
// //       t.test_script_address(t.merkelLoanSpend),
// //       loanOutValue,
// //       loanOutDatum,
// //     )

// //   let colOut =
// //     t.test_output(
// //       t.test_script_address(t.merkelCollateralSpend),
// //       colOutValue,
// //       colOutDatum,
// //     )

// //   let tx =
// //     Transaction {
// //       ..placeholder,
// //       reference_inputs: [configIn],
// //       mint: loanMintedValue,
// //       extra_signatories: [test_owner],
// //       inputs: [userIn, oracleIn],
// //       outputs: [loanOut, colOut, oracleOut],
// //     }

// //   loan_mint.loanMint.mint(
// //     t.oracleMintHash,
// //     t.configMintHash,
// //     mintAction,
// //     t.loanMintHash,
// //     tx,
// //   )
// // }

// // test collateral_ValueFail() {
// //   let test_owner = #"face"

// //   let oref = t.test_oref(#"face", 1)
// //   let cref = t.test_oref(#"cafe", 2)
// //   let rref = t.test_oref(#"dead", 6)

// //   let mintAction = loanMintActionMint(1000, 12, 1111111114)

// //   let loanMintedValue = assets.merge(t.loanTokenValue(), t.loanTokenValue())

// //   let configInDatum = configDatumIn()

// //   let loanDatum = loanDatum(1000, 0, 12, 1111111114, #"beef")
// //   let loanOutDatum = InlineDatum(loanDatum)
// //   let loanOutValue = t.loanTokenValue()

// //   let collateralDatum = collateralDatum(2000, 12, 0)
// //   let colOutDatum = InlineDatum(collateralDatum)
// //   let colOutValue = assets.merge(t.makeAdaValue(1002), t.loanTokenValue())

// //   let oracleInDatum = oracleDatum(2000, 11111112, 1000000, 200000, "USD")
// //   let oracleOutDatum = oracleDatum(1000, 11111114, 1000000, 200000, "USD")
// //   let oInDatum = InlineDatum(oracleInDatum)
// //   let oOutDatum = InlineDatum(oracleOutDatum)

// //   let noDatum = NoDatum

// //   let userIn =
// //     t.test_input(
// //       oref,
// //       t.test_output(t.test_address(#"cafe"), t.makeAdaValue(2010), noDatum),
// //     )

// //   let configIn =
// //     t.test_input(
// //       cref,
// //       t.test_output(
// //         t.test_script_address(t.configValHash),
// //         t.configValue(),
// //         configInDatum,
// //       ),
// //     )

// //   let oracleIn =
// //     t.test_input(
// //       rref,
// //       t.test_output(
// //         t.test_script_address(t.oracleValHash),
// //         t.oracleValue(),
// //         oInDatum,
// //       ),
// //     )

// //   let oracleOut =
// //     t.test_output(
// //       t.test_script_address(t.oracleValHash),
// //       t.oracleValue(),
// //       oOutDatum,
// //     )

// //   let loanOut =
// //     t.test_output(
// //       t.test_script_address(t.merkelLoanSpend),
// //       loanOutValue,
// //       loanOutDatum,
// //     )

// //   let colOut =
// //     t.test_output(
// //       t.test_script_address(t.merkelCollateralSpend),
// //       colOutValue,
// //       colOutDatum,
// //     )

// //   let tx =
// //     Transaction {
// //       ..placeholder,
// //       reference_inputs: [configIn],
// //       mint: loanMintedValue,
// //       extra_signatories: [test_owner],
// //       inputs: [userIn, oracleIn],
// //       outputs: [loanOut, colOut, oracleOut],
// //     }

// //   trace @"VULNERABILITY"
// //   trace @"We should be checking collateral matches expected collateral"
// //   loan_mint.loanMint.mint(
// //     t.oracleMintHash,
// //     t.configMintHash,
// //     mintAction,
// //     t.loanMintHash,
// //     tx,
// //   )?
// // }
