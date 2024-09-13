use aiken/collection/list
use aiken/collection/pairs
use cardano/address.{Script}
use cardano/assets.{PolicyId}
use cardano/transaction.{OutputReference, Transaction}
use ccfl/helpers
use ccfl/types.{LoanDatum, MerkelConfigDatum, MerkelLoanAction}

validator loan(cp: PolicyId) {
  spend(
    _d: Option<LoanDatum>,
    r: MerkelLoanAction,
    _oref: OutputReference,
    tx: Transaction,
  ) {
    let cDatum: MerkelConfigDatum =
      helpers.get_config_datum(tx.reference_inputs, cp)

    expect Some(stakeVal) =
      cDatum.collateralRedeemers
        |> list.at(r.i)

    pairs.has_key(tx.withdrawals, Script(stakeVal))
  }

  else(_) {
    fail
  }
}
