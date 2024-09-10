use aiken/collection/dict.{to_pairs}
use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use cardano/address.{Script}
use cardano/assets.{PolicyId, tokens}
use cardano/transaction.{InlineDatum, Transaction}
use ccfl/types.{
  InterestDatum, MerkelConfigDatum, OBurn, OMint, OracleDatum, OracleMintAction,
}

//             //
// Oracle Mint //
//             //

validator oracleMint(o: VerificationKeyHash, cp: PolicyId) {
  mint(r: OracleMintAction, policyId: PolicyId, tx: Transaction) {
    expect [Pair(_oName, oAmt)] =
      tx.mint
        |> tokens(policyId)
        |> to_pairs()

    when r is {
      OMint {
        exchange,
        timestamp,
        currency,
        supply,
        borrowed,
        base,
        optimal,
        slope1,
        slope2,
        term,
      } -> {
        expect Some(configIn) =
          list.find(
            tx.reference_inputs,
            fn(input) { list.has(assets.policies(input.output.value), cp) },
          )

        expect InlineDatum(datum) = configIn.output.datum
        expect cDatum: MerkelConfigDatum = datum

        expect Some(out) =
          list.find(
            tx.outputs,
            fn(output) {
              expect [Pair(_oName, 1)] =
                output.value
                  |> assets.tokens(policyId)
                  |> dict.to_pairs()
              output.address.payment_credential == Script(cDatum.oracleVal)
            },
          )
        expect InlineDatum(datum) = out.datum
        expect oracleDatum: OracleDatum = datum

        expect oracleDatum.exchange == exchange
        expect oracleDatum.timestamp == timestamp
        expect oracleDatum.currency == currency
        expect oracleDatum.supply == supply
        expect oracleDatum.borrowed == borrowed

        expect Some(interest) =
          list.find(
            tx.outputs,
            fn(output) {
              expect [Pair(_oName, 1)] =
                output.value
                  |> assets.tokens(policyId)
                  |> dict.to_pairs()
              output.address.payment_credential == Script(cDatum.interestVal)
            },
          )
        expect InlineDatum(datum) = interest.datum
        expect interestDatum: InterestDatum = datum

        expect interestDatum.base == base
        expect interestDatum.optimal == optimal
        expect interestDatum.slope1 == slope1
        expect interestDatum.slope2 == slope2
        expect interestDatum.term == term

        list.has(tx.extra_signatories, o) && oAmt == 2
      }
      OBurn -> list.has(tx.extra_signatories, o) && oAmt == -2
    }
  }

  else(_) {
    fail
  }
}
