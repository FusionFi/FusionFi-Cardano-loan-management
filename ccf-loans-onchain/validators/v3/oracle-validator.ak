use aiken/collection/dict.{to_pairs}
use aiken/collection/list.{has}
use aiken/crypto.{VerificationKeyHash}
use cardano/assets.{PolicyId, tokens, without_lovelace}
use cardano/transaction.{
  InlineDatum, Input, Output, OutputReference, Transaction, find_input,
}
use ccfl/helpers.{get_own_singleton_output, has_singleton_input}
use ccfl/types.{OracleAction, OracleClose, OracleDatum, OracleUpdate}

//                  //
// Oracle Validator //
//                  //

validator oracleVault(o: VerificationKeyHash, p: PolicyId) {
  spend(
    datum: Option<OracleDatum>,
    r: OracleAction,
    ownRef: OutputReference,
    tx: Transaction,
  ) {
    expect Some(d) = datum
    expect has_singleton_input(tx, ownRef)
    when r is {
      OracleUpdate { exchange, timestamp, supply, borrowed } -> {
        let out = get_own_singleton_output(tx, ownRef)

        expect [Pair(_, 1)] =
          without_lovelace(out.value)
            |> tokens(p)
            |> to_pairs()

        expect InlineDatum(datum) = out.datum
        expect datum: OracleDatum = datum

        and {
          has(tx.extra_signatories, o),
          timestamp > d.timestamp,
          datum.currency == d.currency,
          datum.timestamp == timestamp,
          datum.supply == supply,
          datum.exchange == exchange,
          // outputDatum.borrowed needs to be updated according to any loan mints or repayments
          datum.borrowed == d.borrowed + borrowed,
        }
      }
      OracleClose -> {
        expect Some(input) = find_input(tx.inputs, ownRef)

        expect [Pair(inName, 1)] =
          // get singleton name
          without_lovelace(input.output.value)
            |> tokens(p)
            |> to_pairs()

        expect [Pair(burnName, -2)] =
          tx.mint
            |> assets.tokens(p)
            |> dict.to_pairs()

        has(tx.extra_signatories, o) && inName == burnName
      }
    }
  }

  else(_) {
    fail
  }
}
