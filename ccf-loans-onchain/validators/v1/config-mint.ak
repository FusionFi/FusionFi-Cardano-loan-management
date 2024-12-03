use aiken/collection/dict
use aiken/collection/list.{find, has}
use aiken/crypto.{VerificationKeyHash}
use cardano/assets.{PolicyId, policies}
use cardano/transaction.{InlineDatum, Output, Transaction}
use ccfl/types.{MConClose, MConUpdate, MerkelConfigAction, MerkelConfigDatum}

//                       //
// Config Minting Policy //
//                       //

validator configMint(o: VerificationKeyHash) {
  mint(r: MerkelConfigAction, policyId: PolicyId, tx: Transaction) {
    let Transaction { outputs, extra_signatories, mint, .. } = tx

    expect [Pair(_tName, tAmt)] =
      mint
        |> assets.tokens(policyId)
        |> dict.to_pairs()

    when r is {
      MConUpdate {
        loanVal,
        colVal,
        rewardsVal,
        oracleVal,
        interestVal,
        collateralRedeemers,
      } -> {
        // // MConUpdate -> {
        // checks the output with the token
        expect Some(ownOut) =
          find(outputs, fn(output) { has(policies(output.value), policyId) })
        // has the appropriate datum        
        expect InlineDatum(datum) = ownOut.datum
        expect outDatum: MerkelConfigDatum = datum
        // output datum matches redeemer && only 1 token is minted && signed by owner
        outDatum.loanVal == loanVal && outDatum.colVal == colVal && outDatum.rewardsVal == rewardsVal && outDatum.oracleVal == oracleVal && outDatum.interestVal == interestVal && outDatum.collateralRedeemers == collateralRedeemers && has(
          extra_signatories,
          o,
        ) && tAmt == 1
      }
      // signed by owner and mint amount is -1
      MConClose -> True
    }
    // has(extra_signatories, o) && tAmt == -1
  }

  else(_) {
    fail
  }
}
