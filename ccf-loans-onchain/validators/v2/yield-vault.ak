use aiken/collection/list
use aiken/collection/pairs
use cardano/address.{Script}
use cardano/assets.{PolicyId}
use cardano/transaction.{OutputReference, Transaction}
use ccfl/helpers
use ccfl/types.{MerkelConfigDatum, YieldAction, YieldDatum}

validator yieldVault(cp: PolicyId) {
  spend(
    _d: Option<YieldDatum>,
    r: YieldAction,
    _oref: OutputReference,
    tx: Transaction,
  ) {
    let cDatum: MerkelConfigDatum =
      helpers.get_config_datum(tx.reference_inputs, cp)

    expect Some(stakeVal) =
      cDatum.collateralRedeemers
        |> list.at(r.i)

    // transaction includes withdrawalRedeemer and signed by withdrawalHash
    pairs.has_key(tx.withdrawals, Script(stakeVal))
  }

  else(_) {
    fail
  }
}
