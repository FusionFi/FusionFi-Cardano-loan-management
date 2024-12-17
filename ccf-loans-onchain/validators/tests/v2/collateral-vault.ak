// use cardano/assets
// use cardano/transaction.{InlineDatum, NoDatum, Transaction, placeholder}
// use ref/collateral_vault
// use tests/tools as t
// use tests/transactions as tx

// //                        //
// // Collateral Valut Tests //
// //                        //

// test collateral_vault() {
//   let configInDatum = tx.refConfigDatumIn()

//   let loanAction = tx.merkelCollateralAction(0)

//   let collateralDatum = tx.collateralDatum(2000, 12, 0)
//   let colOutDatum = InlineDatum(collateralDatum)
//   let colOutValue = assets.merge(t.makeAdaValue(2002), t.refLoanTokenValue())

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
//         t.test_script_address(t.refCollateralSpend),
//         colOutValue,
//         InlineDatum(collateralDatum),
//       ),
//     )

//   let loanOut =
//     t.test_output(
//       t.test_script_address(t.refCollateralSpend),
//       colOutValue,
//       colOutDatum,
//     )

//   let txn =
//     Transaction {
//       ..placeholder,
//       reference_inputs: [configIn],
//       inputs: [userIn, loanIn],
//       outputs: [loanOut],
//       withdrawals: tx.withdrawal(t.refBalance),
//     }

//   collateral_vault.collateral.spend(
//     t.refConfigMint,
//     Some(collateralDatum),
//     loanAction,
//     tx.oref(#"bead", 1),
//     txn,
//   )?
// }
