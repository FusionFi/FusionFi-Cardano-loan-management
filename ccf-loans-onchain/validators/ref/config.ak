use aiken/collection/dict
use aiken/collection/list.{find, has}
use aiken/crypto.{VerificationKeyHash}
use cardano/address.{Script}
use cardano/assets.{PolicyId, policies}
use cardano/transaction.{InlineDatum, Output, OutputReference, Transaction}
use ccfl/helpers
use ccfl/types.{MConClose, MConUpdate, MerkelConfigAction, MerkelConfigDatum}

//                  //
// Config Validator //
//                  //

validator config(o: VerificationKeyHash) {
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
        // checks the output with the token
        expect Some(ownOut) =
          find(outputs, fn(output) { has(policies(output.value), policyId) })
        // has the appropriate datum        
        expect InlineDatum(datum) = ownOut.datum
        expect outDatum: MerkelConfigDatum = datum

        // output datum matches redeemer && only 1 token is minted && signed by owner
        and {
          outDatum.loanVal == loanVal,
          outDatum.colVal == colVal,
          outDatum.rewardsVal == rewardsVal,
          outDatum.oracleVal == oracleVal,
          outDatum.interestVal == interestVal,
          outDatum.collateralRedeemers == collateralRedeemers,
          has(extra_signatories, o),
          tAmt == 1,
        }
      }
      // signed by owner and mint amount is -1
      MConClose -> has(extra_signatories, o) && tAmt == -1
    }
  }

  spend(
    _d: Option<MerkelConfigDatum>,
    r: MerkelConfigAction,
    oref: OutputReference,
    tx: Transaction,
  ) {
    let Transaction { extra_signatories, .. } = tx

    when r is {
      MConUpdate {
        loanVal,
        colVal,
        rewardsVal,
        oracleVal,
        interestVal,
        collateralRedeemers,
      } -> {
        // checks single val IO & returns those as a pair
        let Pair(ownIn, ownOut) =
          helpers.oneIO_List(oref, tx.inputs, tx.outputs)

        expect Script(cp) = ownIn.output.address.payment_credential

        // checks output datum
        expect InlineDatum(datum) = ownOut.datum
        expect outDatum: MerkelConfigDatum = datum

        // checks signed by owner, has a Config Token Datum values match redeemer
        and {
          has(extra_signatories, o),
          has(policies(ownOut.value), cp),
          outDatum.loanVal == loanVal,
          outDatum.colVal == colVal,
          outDatum.rewardsVal == rewardsVal,
          outDatum.oracleVal == oracleVal,
          outDatum.interestVal == interestVal,
          outDatum.collateralRedeemers == collateralRedeemers,
        }
      }
      // checks signed by owner
      MConClose -> has(extra_signatories, o)
    }
  }

  else(_) {
    fail
  }
}
