use aiken/collection/dict
use aiken/collection/list.{find, has}
use aiken/crypto.{VerificationKeyHash}
use cardano/address.{Script}
use cardano/assets.{PolicyId, policies}
use cardano/transaction.{InlineDatum, Input, Output, Transaction}
use ccfl/types.{
  LoanDatum, MerkelConfigDatum, RewardBurn, RewardMint, RewardsAction,
}

//                              //
// Rewards Token Minting Policy //
//                              //

validator rewardsMint(_o: VerificationKeyHash, cp: PolicyId, lp: PolicyId) {
  mint(r: RewardsAction, policyId: PolicyId, tx: Transaction) {
    let Transaction { mint, inputs, .. } = tx

    expect Some(refIn) =
      find(
        tx.reference_inputs,
        fn(input) { has(policies(input.output.value), cp) },
      )

    expect InlineDatum(datum) = refIn.output.datum
    expect cDatum: MerkelConfigDatum = datum

    expect [Pair(tName, tAmt)] =
      mint
        |> assets.tokens(policyId)
        |> dict.to_pairs()

    expect _burnedLoanList =
      mint
        |> assets.tokens(lp)
        |> dict.to_pairs()

    when r is {
      RewardMint -> {
        expect Some(loanIn) =
          find(
            inputs,
            fn(input) {
              has(policies(input.output.value), lp) && input.output.address.payment_credential == Script(
                cDatum.loanVal,
              )
            },
          )

        expect InlineDatum(datum) = loanIn.output.datum
        expect inDatum: LoanDatum = datum

        expect [Pair(_lName, 1)] =
          loanIn.output.value
            |> assets.tokens(lp)
            |> dict.to_pairs()

        tName == "" && tAmt == inDatum.rewards && inDatum.amount == 0
      }
      RewardBurn -> tAmt <= 0
    }
  }

  else(_) {
    fail
  }
}
