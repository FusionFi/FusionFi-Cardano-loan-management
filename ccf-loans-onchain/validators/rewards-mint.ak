use aiken/dict
use aiken/list.{find, has}
use aiken/transaction.{
  InlineDatum, Input, Mint, NoDatum, Output, ScriptContext, Transaction,
  find_script_outputs, placeholder,
}
use aiken/transaction/value.{PolicyId, policies}
use ccfl/types.{
  LoanDatum, MerkelConfigDatum, RewardBurn, RewardMint, RewardsAction,
  VerificationKeyHash,
}
use tests/tools as t
use tests/transactions as tx

//                              //
// Rewards Token Minting Policy //
//                              //

validator(o: VerificationKeyHash, cp: PolicyId, lp: PolicyId) {
  fn rewardsMint(r: RewardsAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Mint(policyId) = purpose
    let Transaction { mint, outputs, .. } = transaction

    expect Some(refIn) =
      find(
        transaction.reference_inputs,
        fn(input) { has(policies(input.output.value), cp) },
      )

    expect InlineDatum(datum) = refIn.output.datum
    expect cDatum: MerkelConfigDatum = datum

    expect [Pair(tName, tAmt)] =
      mint
        |> value.from_minted_value()
        |> value.tokens(policyId)
        |> dict.to_pairs()

    when r is {
      RewardMint -> {
        expect Some(loanIn) =
          find(
            transaction.inputs,
            fn(input) { has(policies(input.output.value), lp) },
          )

        expect InlineDatum(datum) = loanIn.output.datum
        expect lDatum: LoanDatum = datum

        expect [] = find_script_outputs(outputs, cDatum.loanVal)

        tAmt == lDatum.rewards && tName == ""
      }

      RewardBurn -> tAmt <= -1
    }
  }
}
//                    //
// Rewards Mint Tests //
//                    //

// test rewards_mint() {
//   let loanValue = 1000

//   let test_owner = #"face"

//   // let test_user = #"cafe"
//   let oref = t.test_oref(#"face", 1)
//   let rref = t.test_oref(#"dead", 6)

//   let rewardsAction = tx.rewardsActionMint()

//   let outDatum = NoDatum

//   let loanInput = tx.loanInput(1, loanValue)

//   let userOutput =
//     t.test_output(
//       t.test_address(test_owner),
//       t.rewardsValue(loanValue),
//       outDatum,
//     )

//   let configIn = tx.configInput()

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       mint: t.rewardsMintedValue(loanValue),
//       extra_signatories: [test_owner],
//       inputs: [loanInput],
//       outputs: [userOutput],
//     }

//   let ctx = ScriptContext { purpose: Mint(t.rewardsMintHash), transaction: tx }

//   rewardsMint(test_owner, t.configMintHash, t.loanMintHash, rewardsAction, ctx)?
// }

// test rewards_mint_qty_fail() fail {
//   let test_owner = #"face"

//   // let test_user = #"cafe"
//   let oref = t.test_oref(#"face", 1)
//   let rref = t.test_oref(#"dead", 6)

//   let rewardsAction = rewardsActionMint()

//   let configDatum =
//     configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
//   let configInDatum = InlineDatum(configDatum)

//   let loanDatum = loanDatum(1000, 15, 1000, 2, 1111111190)
//   let loanInDatum = InlineDatum(loanDatum)
//   let outDatum = NoDatum

//   let loanInput =
//     t.test_input(
//       oref,
//       t.test_output(
//         t.test_script_address(t.loanValHash),
//         t.loanValue(),
//         loanInDatum,
//       ),
//     )

//   let userOutput =
//     t.test_output(t.test_address(test_owner), t.rewardsValue(100), outDatum)
//   let configIn =
//     t.test_input(
//       rref,
//       t.test_output(
//         t.test_script_address(t.configValHash),
//         t.configValue(),
//         configInDatum,
//       ),
//     )

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       mint: t.rewardsMintedValue(100),
//       extra_signatories: [test_owner],
//       inputs: [loanInput],
//       outputs: [userOutput],
//     }

//   let ctx = ScriptContext { purpose: Mint(t.rewardsMintHash), transaction: tx }

//   rewardsMint(test_owner, t.configMintHash, t.loanMintHash, rewardsAction, ctx)?
// }

// test rewards_mint_loanOutput_fail() fail {
//   let test_owner = #"face"

//   // let test_user = #"cafe"
//   let oref = t.test_oref(#"face", 1)
//   let rref = t.test_oref(#"dead", 6)

//   let rewardsAction = rewardsActionMint()

//   let configDatum =
//     configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
//   let configInDatum = InlineDatum(configDatum)

//   let loanDatum = loanDatum(1000, 15, 1000, 2, 1111111190)
//   let loanInDatum = InlineDatum(loanDatum)
//   let outDatum = NoDatum

//   let loanInput =
//     t.test_input(
//       oref,
//       t.test_output(
//         t.test_script_address(t.loanValHash),
//         t.loanValue(),
//         loanInDatum,
//       ),
//     )

//   let loanOutput =
//     t.test_output(
//       t.test_script_address(t.loanValHash),
//       t.loanValue(),
//       loanInDatum,
//     )

//   let userOutput =
//     t.test_output(t.test_address(test_owner), t.rewardsValue(1000), outDatum)
//   let configIn =
//     t.test_input(
//       rref,
//       t.test_output(
//         t.test_script_address(t.configValHash),
//         t.configValue(),
//         configInDatum,
//       ),
//     )

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

// test rewards_mint_config_fail() fail {
//   let test_owner = #"face"

//   // let test_user = #"cafe"
//   let oref = t.test_oref(#"face", 1)
//   let rref = t.test_oref(#"dead", 6)

//   let rewardsAction = rewardsActionMint()

//   let configDatum =
//     configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
//   let configInDatum = InlineDatum(configDatum)

//   let loanDatum = loanDatum(1000, 15, 1000, 2, 1111111190)
//   let loanInDatum = InlineDatum(loanDatum)
//   let outDatum = NoDatum

//   let loanInput =
//     t.test_input(
//       oref,
//       t.test_output(
//         t.test_script_address(t.loanValHash),
//         t.loanValue(),
//         loanInDatum,
//       ),
//     )

//   let userOutput =
//     t.test_output(t.test_address(test_owner), t.rewardsValue(1000), outDatum)
//   let configIn =
//     t.test_input(
//       rref,
//       t.test_output(
//         t.test_script_address(t.configValHash),
//         t.makeAdaValue(2),
//         configInDatum,
//       ),
//     )

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       mint: t.rewardsMintedValue(1000),
//       extra_signatories: [test_owner],
//       inputs: [loanInput],
//       outputs: [userOutput],
//     }

//   let ctx = ScriptContext { purpose: Mint(t.rewardsMintHash), transaction: tx }

//   rewardsMint(test_owner, t.configMintHash, t.loanMintHash, rewardsAction, ctx)?
// }

// test rewards_mint_noRewards_fail() fail {
//   let test_owner = #"face"

//   // let test_user = #"cafe"
//   let oref = t.test_oref(#"face", 1)
//   let rref = t.test_oref(#"dead", 6)

//   let rewardsAction = rewardsActionMint()

//   let configDatum =
//     configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
//   let configInDatum = InlineDatum(configDatum)

//   let loanDatum = loanDatum(1000, 15, 0, 2, 1111111190)
//   let loanInDatum = InlineDatum(loanDatum)
//   let outDatum = NoDatum

//   let loanInput =
//     t.test_input(
//       oref,
//       t.test_output(
//         t.test_script_address(t.loanValHash),
//         t.loanValue(),
//         loanInDatum,
//       ),
//     )

//   let userOutput =
//     t.test_output(t.test_address(test_owner), t.rewardsValue(1000), outDatum)
//   let configIn =
//     t.test_input(
//       rref,
//       t.test_output(
//         t.test_script_address(t.configValHash),
//         t.configValue(),
//         configInDatum,
//       ),
//     )

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       mint: t.rewardsMintedValue(1000),
//       extra_signatories: [test_owner],
//       inputs: [loanInput],
//       outputs: [userOutput],
//     }

//   let ctx = ScriptContext { purpose: Mint(t.rewardsMintHash), transaction: tx }

//   rewardsMint(test_owner, t.configMintHash, t.loanMintHash, rewardsAction, ctx)?
// }

// test rewards_mint_fakeLoanIn_fail() fail {
//   // this fails because we dont check the incoming script hash
//   // if we can't remove a loan token from our control, it doesnt matter
//   // but we could verify the loanIn Credential as we have the config refInput
//   let test_owner = #"face"

//   // let test_user = #"cafe"
//   let oref = t.test_oref(#"face", 1)
//   let rref = t.test_oref(#"dead", 6)

//   let rewardsAction = rewardsActionMint()

//   let configDatum =
//     configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
//   let configInDatum = InlineDatum(configDatum)

//   let loanDatum = loanDatum(1000, 15, 1000, 2, 1111111190)
//   let loanInDatum = InlineDatum(loanDatum)
//   let outDatum = NoDatum

//   let loanInput =
//     t.test_input(
//       oref,
//       t.test_output(
//         t.test_script_address(t.configValHash),
//         t.loanValue(),
//         loanInDatum,
//       ),
//     )

//   let userOutput =
//     t.test_output(t.test_address(test_owner), t.rewardsValue(1000), outDatum)
//   let configIn =
//     t.test_input(
//       rref,
//       t.test_output(
//         t.test_script_address(t.configValHash),
//         t.configValue(),
//         configInDatum,
//       ),
//     )

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       mint: t.rewardsMintedValue(1000),
//       extra_signatories: [test_owner],
//       inputs: [loanInput],
//       outputs: [userOutput],
//     }

//   let ctx = ScriptContext { purpose: Mint(t.rewardsMintHash), transaction: tx }

//   rewardsMint(test_owner, t.configMintHash, t.loanMintHash, rewardsAction, ctx)?
// }
