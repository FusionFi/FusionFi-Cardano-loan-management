// use cardano/transaction.{InlineDatum, NoDatum, Transaction, placeholder}
// use ref/loan_vault
// use tests/tools as t
// use tests/transactions as tx

// //                  //
// // Loan Vault Tests //
// //                  //

// test loan_vault() {
//   let configInDatum = tx.refConfigDatumIn()

//   let loanAction = tx.merkelLoanAction(0)

//   let loanInDatum = tx.loanDatum(1000, 0, 12, 1111111111, #"beef")
//   let loanDatum = tx.loanDatum(1000, 0, 12, 1111111114, #"beef")
//   let loanOutDatum = InlineDatum(loanDatum)
//   let loanOutValue = t.refLoanTokenValue()

//   let userIn =
//     t.test_input(
//       tx.oref(#"beef", 2),
//       t.test_output(t.test_address(#"cafe"), t.makeAdaValue(2010), NoDatum),
//     )

//   let configIn =
//     t.test_input(
//       tx.oref(#"aced", 1),
//       t.test_output(
//         t.test_script_address(t.refConfigSpend),
//         t.refConfigValue(),
//         configInDatum,
//       ),
//     )

//   let loanIn =
//     t.test_input(
//       tx.oref(#"bead", 1),
//       t.test_output(
//         t.test_script_address(t.refLoanSpend),
//         loanOutValue,
//         InlineDatum(loanInDatum),
//       ),
//     )

//   let loanOut =
//     t.test_output(
//       t.test_script_address(t.refLoanSpend),
//       loanOutValue,
//       loanOutDatum,
//     )

//   let tx =
//     Transaction {
//       ..placeholder,
//       reference_inputs: [configIn],
//       inputs: [userIn, loanIn],
//       outputs: [loanOut],
//       withdrawals: tx.withdrawal(t.refBalance),
//     }

//   loan_vault.loan.spend(
//     t.refConfigMint,
//     Some(loanInDatum),
//     loanAction,
//     tx.oref(#"bead", 1),
//     tx,
//   )?
// }
// // test loan_datumFail() {
// //   let configInDatum = tx.configDatumIn()

// //   let loanAction = tx.merkelLoanAction(3)

// //   let loanInDatum = tx.loanDatum(1000, 0, 12, 1111111111, #"beef")
// //   let loanDatum = tx.loanDatum(1000, 0, 12, 1111111114, #"beef")
// //   let loanOutDatum = InlineDatum(loanDatum)
// //   let loanOutValue = t.loanTokenValue()

// //   let userIn =
// //     t.test_input(
// //       tx.oref(#"beef", 2),
// //       t.test_output(t.test_address(#"cafe"), t.makeAdaValue(2010), NoDatum),
// //     )

// //   let configIn =
// //     t.test_input(
// //       tx.oref(#"aced", 1),
// //       t.test_output(
// //         t.test_script_address(t.configValHash),
// //         t.configValue(),
// //         configInDatum,
// //       ),
// //     )

// //   let loanIn =
// //     t.test_input(
// //       tx.oref(#"bead", 1),
// //       t.test_output(
// //         t.test_script_address(t.merkelLoanSpend),
// //         loanOutValue,
// //         InlineDatum(loanInDatum),
// //       ),
// //     )

// //   let loanOut =
// //     t.test_output(
// //       t.test_script_address(t.merkelLoanSpend),
// //       loanOutValue,
// //       loanOutDatum,
// //     )

// //   let tx =
// //     Transaction {
// //       ..placeholder,
// //       reference_inputs: [configIn],
// //       inputs: [userIn, loanIn],
// //       outputs: [loanOut],
// //       withdrawals: tx.withdrawal(t.merkelBalance),
// //     }

// //   loan_vault.loan.spend(
// //     t.configMintHash,
// //     Some(loanInDatum),
// //     loanAction,
// //     tx.oref(#"bead", 1),
// //     tx,
// //   )?
// // }
