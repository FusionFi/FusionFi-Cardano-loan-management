use aiken/dict
use aiken/list.{find, has}
use aiken/transaction.{
  InlineDatum, Input, Mint, NoDatum, Output, ScriptContext, Transaction,
  placeholder,
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

validator(_o: VerificationKeyHash, cp: PolicyId, lp: PolicyId) {
  fn rewardsMint(r: RewardsAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Mint(policyId) = purpose
    let Transaction { mint, inputs, outputs, .. } = transaction

    expect Some(refIn) =
      find(
        transaction.reference_inputs,
        fn(input) { has(policies(input.output.value), cp) },
      )

    expect InlineDatum(datum) = refIn.output.datum
    expect _cDatum: MerkelConfigDatum = datum

    expect [Pair(tName, tAmt)] =
      mint
        |> value.from_minted_value()
        |> value.tokens(policyId)
        |> dict.to_pairs()

    when r is {
      RewardMint -> {
        expect Some(loanIn) =
          find(inputs, fn(input) { has(policies(input.output.value), lp) })

        expect InlineDatum(datum) = loanIn.output.datum
        expect inDatum: LoanDatum = datum

        expect Some(loanOut) =
          find(
            outputs,
            fn(out) {
              value.without_lovelace(out.value) == value.without_lovelace(
                loanIn.output.value,
              )
            },
          )
        expect InlineDatum(datum) = loanOut.datum
        expect outDatum: LoanDatum = datum

        tName == "" && tAmt == inDatum.rewards && outDatum.rewards == 0 && inDatum.amount == 0 && outDatum.amount == 0 && inDatum.term == outDatum.term && inDatum.timestamp == outDatum.timestamp && inDatum.oracle == outDatum.oracle
      }

      RewardBurn -> tAmt <= 0
    }
  }
}

//                    //
// Rewards Mint Tests //
//                    //

test rewards_mint() {
  let inLoanDatum = tx.loanDatum(0, 1000, 0, 1721819831, #"beef")
  let outLoanDatum = tx.loanDatum(0, 0, 0, 1721819831, #"beef")

  let test_owner = #"face"

  // let test_user = #"cafe"
  // let oref = t.test_oref(#"face", 1)
  // let rref = t.test_oref(#"dead", 6)
  let rewardsAction = tx.rewardsActionMint()

  let outDatum = NoDatum

  let loanInput =
    t.test_input(
      tx.oref(#"face", 1),
      t.test_output(
        t.test_script_address(t.mLoan),
        t.loanValue(),
        InlineDatum(inLoanDatum),
      ),
    )

  let userOutput =
    t.test_output(t.test_address(test_owner), t.rewardsValue(1000), outDatum)

  let loanOutput =
    t.test_output(
      t.test_script_address(t.mLoan),
      t.loanValue(),
      InlineDatum(outLoanDatum),
    )

  let configIn = tx.configInput()

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      mint: t.rewardsMintedValue(1000),
      extra_signatories: [test_owner],
      inputs: [loanInput],
      outputs: [userOutput, loanOutput],
    }

  let ctx = ScriptContext { purpose: Mint(t.rewardsMintHash), transaction: tx }

  rewardsMint(test_owner, t.configMintHash, t.loanMintHash, rewardsAction, ctx)?
}

test mint_qtyFail() fail {
  let loanValue = 1000
  let rewardsValue = 100

  let test_owner = #"face"

  // let test_user = #"cafe"
  // let oref = t.test_oref(#"face", 1)
  // let rref = t.test_oref(#"dead", 6)
  let rewardsAction = tx.rewardsActionMint()

  let outDatum = NoDatum

  let loanInput = tx.loanInput(1, loanValue)

  let userOutput =
    t.test_output(
      t.test_address(test_owner),
      t.rewardsValue(rewardsValue),
      outDatum,
    )

  let configIn = tx.configInput()

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      mint: t.rewardsMintedValue(rewardsValue),
      extra_signatories: [test_owner],
      inputs: [loanInput],
      outputs: [userOutput],
    }

  let ctx = ScriptContext { purpose: Mint(t.rewardsMintHash), transaction: tx }

  rewardsMint(test_owner, t.configMintHash, t.loanMintHash, rewardsAction, ctx)?
}
