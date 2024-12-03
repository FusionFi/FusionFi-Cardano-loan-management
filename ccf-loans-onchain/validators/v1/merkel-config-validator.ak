use aiken/collection/list.{has}
use aiken/crypto.{VerificationKeyHash}
use cardano/assets.{PolicyId, policies}
use cardano/transaction.{InlineDatum, Output, OutputReference, Transaction}
use ccfl/helpers.{get_own_singleton_output}
use ccfl/types.{MConClose, MConUpdate, MerkelConfigAction, MerkelConfigDatum}

//                         //
// Merkel Config Validator //
//                         //

validator configVal(o: VerificationKeyHash, cp: PolicyId) {
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
        // gets own output (ensures there is only one)
        let ownOut = get_own_singleton_output(tx, oref)
        // checks output datum
        expect InlineDatum(datum) = ownOut.datum
        expect outDatum: MerkelConfigDatum = datum
        // checks signed by owner, has a Config Token Datum values match redeemer
        has(extra_signatories, o) && has(policies(ownOut.value), cp) && outDatum.loanVal == loanVal && outDatum.colVal == colVal && outDatum.rewardsVal == rewardsVal && outDatum.oracleVal == oracleVal && outDatum.interestVal == interestVal && outDatum.collateralRedeemers == collateralRedeemers
      }
      // checks signed by owner
      MConClose -> has(extra_signatories, o)
    }
  }

  else(_) {
    fail
  }
}
