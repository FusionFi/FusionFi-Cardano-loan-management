use aiken/collection/list
use aiken/collection/pairs
use cardano/address.{Script}
use cardano/assets.{PolicyId}
use cardano/transaction.{OutputReference, Transaction}
use ccfl/helpersv3 as h
use ccfl/typesv3.{CollateralDatum, MerkelCollateralAction, MerkelConfigDatum}

validator collateral(cp: PolicyId) {
  spend(
    _d: Option<CollateralDatum>,
    r: MerkelCollateralAction,
    _oref: OutputReference,
    tx: Transaction,
  ) {
    let cDatum: MerkelConfigDatum = h.get_config_datum(tx.reference_inputs, cp)

    expect Some(stakeVal) =
      cDatum.collateralRedeemers
        |> list.at(r.i)

    pairs.has_key(tx.withdrawals, Script(stakeVal))
  }

  else(_) {
    fail
  }
}
