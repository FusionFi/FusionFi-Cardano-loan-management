//                      //
// Rewards Policy Tests //
//                      //

// test rewards_mint() {
//   let inLoanDatum = tx.loanDatum(0, 1000, 0, 1721819831, #"beef")
//   let outLoanDatum = tx.loanDatum(0, 0, 0, 1721819831, #"beef")

//   let test_owner = #"face"

//   // let test_user = #"cafe"
//   // let oref = t.test_oref(#"face", 1)
//   // let rref = t.test_oref(#"dead", 6)
//   let rewardsAction = tx.rewardsActionMint()

//   let outDatum = NoDatum

//   let loanInput =
//     t.test_input(
//       tx.oref(#"face", 1),
//       t.test_output(
//         t.test_script_address(t.mLoan),
//         t.loanValue(),
//         InlineDatum(inLoanDatum),
//       ),
//     )

//   let userOutput =
//     t.test_output(t.test_address(test_owner), t.rewardsValue(1000), outDatum)

//   let loanOutput =
//     t.test_output(
//       t.test_script_address(t.mLoan),
//       t.loanValue(),
//       InlineDatum(outLoanDatum),
//     )

//   let configIn = tx.configInput()

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       mint: t.rewardsMintedValue(1000),
//       extra_signatories: [test_owner],
//       inputs: [loanInput],
//       outputs: [userOutput, loanOutput],
//     }

//   let ctx = ScriptContext { purpose: Mint(t.rewardsMintHash), transaction: tx }

//   rewardsMint(test_owner, t.configMintHash, t.loanMintHash, rewardsAction, ctx)?
// }

// test mint_qtyFail() fail {
//   let loanValue = 1000
//   let rewardsValue = 100

//   let test_owner = #"face"

//   // let test_user = #"cafe"
//   // let oref = t.test_oref(#"face", 1)
//   // let rref = t.test_oref(#"dead", 6)
//   let rewardsAction = tx.rewardsActionMint()

//   let outDatum = NoDatum

//   let loanInput = tx.loanInput(1, loanValue)

//   let userOutput =
//     t.test_output(
//       t.test_address(test_owner),
//       t.rewardsValue(rewardsValue),
//       outDatum,
//     )

//   let configIn = tx.configInput()

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       mint: t.rewardsMintedValue(rewardsValue),
//       extra_signatories: [test_owner],
//       inputs: [loanInput],
//       outputs: [userOutput],
//     }

//   let ctx = ScriptContext { purpose: Mint(t.rewardsMintHash), transaction: tx }

//   rewardsMint(test_owner, t.configMintHash, t.loanMintHash, rewardsAction, ctx)?
// }
