use aiken/collection/dict.{to_pairs}
use aiken/collection/list.{has}
use aiken/crypto.{VerificationKeyHash}
use cardano/assets.{PolicyId, tokens, without_lovelace}
use cardano/transaction.{
  InlineDatum, Input, Output, OutputReference, Transaction, find_input,
}
use ccfl/helpers.{get_own_singleton_output, has_singleton_input}
use ccfl/types.{InterestAction, InterestClose, InterestDatum, InterestUpdate}

// validator for handling updating and enforcing rates

validator interest(op: PolicyId, o: VerificationKeyHash) {
  spend(
    _d: Option<InterestDatum>,
    r: InterestAction,
    ownRef: OutputReference,
    tx: Transaction,
  ) {
    expect has_singleton_input(tx, ownRef)
    when r is {
      InterestUpdate { base, optimal, slope1, slope2, term } -> {
        let out = get_own_singleton_output(tx, ownRef)

        expect [Pair(_, 1)] =
          without_lovelace(out.value)
            |> tokens(op)
            |> to_pairs()

        expect InlineDatum(datum) = out.datum
        expect datum: InterestDatum = datum

        has(tx.extra_signatories, o) && datum.base == base && datum.optimal == optimal && datum.slope1 == slope1 && datum.slope2 == slope2 && datum.term == term
      }
      InterestClose -> {
        expect Some(ownIn) = find_input(tx.inputs, ownRef)

        expect [Pair(inName, 1)] =
          // get singleton name
          without_lovelace(ownIn.output.value)
            |> tokens(op)
            |> to_pairs()

        expect [Pair(burnName, -2)] =
          tx.mint
            |> assets.tokens(op)
            |> dict.to_pairs()

        has(tx.extra_signatories, o) && inName == burnName
      }
    }
  }

  else(_) {
    fail
  }
}
