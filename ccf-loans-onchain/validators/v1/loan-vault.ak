use aiken/collection/list
use aiken/collection/pairs
use cardano/address.{Script}
use cardano/assets.{PolicyId}
use cardano/transaction.{InlineDatum, OutputReference, Transaction}
use ccfl/types.{LoanDatum, MerkelConfigDatum, MerkelLoanAction}

validator loan(cp: PolicyId) {
  spend(
    _d: Option<LoanDatum>,
    r: MerkelLoanAction,
    _oref: OutputReference,
    transaction: Transaction,
  ) {
    let Transaction { reference_inputs, withdrawals, .. } = transaction

    expect Some(configIn) =
      list.find(
        reference_inputs,
        fn(input) { list.has(assets.policies(input.output.value), cp) },
      )

    expect InlineDatum(datum) = configIn.output.datum
    expect cDatum: MerkelConfigDatum = datum

    expect Some(stakeVal) =
      cDatum.collateralRedeemers
        |> list.at(r.i)

    pairs.has_key(withdrawals, Script(stakeVal))
  }

  else(_) {
    fail
  }
}
