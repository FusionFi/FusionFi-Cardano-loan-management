// use cardano/transaction.{InlineDatum, Transaction, placeholder}
// use ref/oracle_validator
// use tests/tools as t
// use tests/transactions.{oracleAction, oracleDatum}

// //                        //
// // Oracle Validator Tests //
// //                        //

// test oracle_vault() {
//   let test_owner = #"face"

//   let oref = t.test_oref(#"face", 1)

//   let oracleDatum1 = oracleDatum(1, 11111111, 1000000, 500000, "beef")
//   let oracleDatum2 = oracleDatum(2, 11111112, 1000000, 500000, "beef")
//   let inDatum = InlineDatum(oracleDatum1)
//   let outDatum = InlineDatum(oracleDatum2)

//   let oracleInput =
//     t.test_input(
//       oref,
//       t.test_output(
//         t.test_script_address(t.refOracleSpend),
//         t.refOracleValue(),
//         inDatum,
//       ),
//     )

//   let oracleOutput =
//     t.test_output(
//       t.test_script_address(t.refOracleSpend),
//       t.refOracleValue(),
//       outDatum,
//     )

//   let oracleAction = oracleAction(2, 11111112, 1000000, 500000)

//   let tx =
//     Transaction {
//       ..placeholder,
//       extra_signatories: [test_owner],
//       inputs: [oracleInput],
//       outputs: [oracleOutput],
//     }

//   oracle_validator.oracleVault.spend(
//     test_owner,
//     t.refOracleMint,
//     Some(oracleDatum1),
//     oracleAction,
//     oref,
//     tx,
//   )
// }
// // test oracle_vault_datum_fail() fail {
// //   let test_owner = #"face"

// //   let oref = t.test_oref(#"face", 1)

// //   let oracleDatum1 = oracleDatum(2, 11111111, 1000000, 500000, "beef")
// //   let oracleDatum2 = oracleDatum(2, 11111112, 1000000, 500000, "cafe")
// //   let inDatum = InlineDatum(oracleDatum1)
// //   let outDatum = InlineDatum(oracleDatum2)

// //   let oracleInput =
// //     t.test_input(
// //       oref,
// //       t.test_output(
// //         t.test_script_address(t.oracleValHash),
// //         t.oracleValue(),
// //         inDatum,
// //       ),
// //     )

// //   let oracleOutput =
// //     t.test_output(
// //       t.test_script_address(t.oracleValHash),
// //       t.oracleValue(),
// //       outDatum,
// //     )

// //   let oracleAction = oracleAction(2, 11111112, 1000000, 500000)

// //   let tx =
// //     Transaction {
// //       ..placeholder,
// //       extra_signatories: [test_owner],
// //       inputs: [oracleInput],
// //       outputs: [oracleOutput],
// //     }

// //   oracle_validator.oracleVault.spend(
// //     test_owner,
// //     t.oracleMintHash,
// //     Some(oracleDatum1),
// //     oracleAction,
// //     oref,
// //     tx,
// //   )
// // }

// // test oracle_vault_redeemer_fail() fail {
// //   let test_owner = #"face"

// //   let oref = t.test_oref(#"face", 1)

// //   let oracleDatum1 = oracleDatum(2, 11111111, 1000000, 500000, "beef")
// //   let oracleDatum2 = oracleDatum(2, 11111112, 1000000, 500000, "beef")
// //   let inDatum = InlineDatum(oracleDatum1)
// //   let outDatum = InlineDatum(oracleDatum2)

// //   let oracleInput =
// //     t.test_input(
// //       oref,
// //       t.test_output(
// //         t.test_script_address(t.oracleValHash),
// //         t.oracleValue(),
// //         inDatum,
// //       ),
// //     )

// //   let oracleOutput =
// //     t.test_output(
// //       t.test_script_address(t.oracleValHash),
// //       t.oracleValue(),
// //       outDatum,
// //     )

// //   let oracleAction = oracleAction(3, 11111112, 1000000, 500000)

// //   let tx =
// //     Transaction {
// //       ..placeholder,
// //       extra_signatories: [test_owner],
// //       inputs: [oracleInput],
// //       outputs: [oracleOutput],
// //     }

// //   oracle_validator.oracleVault.spend(
// //     test_owner,
// //     t.oracleMintHash,
// //     Some(oracleDatum1),
// //     oracleAction,
// //     oref,
// //     tx,
// //   )
// // }

// // test oracle_vault_sig_fail() fail {
// //   let test_owner = #"face"

// //   let oref = t.test_oref(#"face", 1)

// //   let oracleDatum1 = oracleDatum(2, 11111111, 1000000, 500000, "beef")
// //   let oracleDatum2 = oracleDatum(2, 11111112, 1000000, 500000, "beef")
// //   let inDatum = InlineDatum(oracleDatum1)
// //   let outDatum = InlineDatum(oracleDatum2)

// //   let oracleInput =
// //     t.test_input(
// //       oref,
// //       t.test_output(
// //         t.test_script_address(t.oracleValHash),
// //         t.oracleValue(),
// //         inDatum,
// //       ),
// //     )

// //   let oracleOutput =
// //     t.test_output(
// //       t.test_script_address(t.oracleValHash),
// //       t.oracleValue(),
// //       outDatum,
// //     )

// //   let oracleAction = oracleAction(2, 11111112, 1000000, 500000)

// //   let tx =
// //     Transaction {
// //       ..placeholder,
// //       extra_signatories: [#"dead"],
// //       inputs: [oracleInput],
// //       outputs: [oracleOutput],
// //     }

// //   oracle_validator.oracleVault.spend(
// //     test_owner,
// //     t.oracleMintHash,
// //     Some(oracleDatum1),
// //     oracleAction,
// //     oref,
// //     tx,
// //   )
// // }

// // test oracle_vault_token_fail() fail {
// //   let test_owner = #"face"

// //   let oref = t.test_oref(#"face", 1)

// //   let oracleDatum1 = oracleDatum(2, 11111111, 1000000, 500000, "beef")
// //   let oracleDatum2 = oracleDatum(2, 11111112, 1000000, 500000, "beef")
// //   let inDatum = InlineDatum(oracleDatum1)
// //   let outDatum = InlineDatum(oracleDatum2)

// //   let oracleInput =
// //     t.test_input(
// //       oref,
// //       t.test_output(
// //         t.test_script_address(t.oracleValHash),
// //         t.oracleValue(),
// //         inDatum,
// //       ),
// //     )

// //   let oracleOutput =
// //     t.test_output(
// //       t.test_script_address(t.oracleValHash),
// //       t.makeAdaValue(2),
// //       outDatum,
// //     )

// //   let oracleAction = oracleAction(2, 11111112, 1000000, 500000)

// //   let tx =
// //     Transaction {
// //       ..placeholder,
// //       extra_signatories: [test_owner],
// //       inputs: [oracleInput],
// //       outputs: [oracleOutput],
// //     }

// //   oracle_validator.oracleVault.spend(
// //     test_owner,
// //     t.oracleMintHash,
// //     Some(oracleDatum1),
// //     oracleAction,
// //     oref,
// //     tx,
// //   )
// // }
