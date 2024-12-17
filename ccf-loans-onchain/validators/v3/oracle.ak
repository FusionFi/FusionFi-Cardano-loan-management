use aiken/collection/dict.{to_pairs}
use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use cardano/address.{Script}
use cardano/assets.{PolicyId, tokens}
use cardano/transaction.{InlineDatum, OutputReference, Transaction}
use ccfl/helpersv3 as h
use ccfl/typesv3.{
  InterestDatum, MerkelConfigDatum, OBurn, OMint, OracleAction, OracleClose,
  OracleDatum, OracleMintAction, OracleUpdate, SupplyDatum,
}

//             //
// Oracle Mint //
//             //

// Because we want to supply assets as part of a P2P protocol, we need to create
// an additional OralceToken to be used as a Beacon token for the supply pool
// it will be sent to the supply pool to create a new supply feed that users
// can add their own assets to.
validator oracle(o: VerificationKeyHash, cp: PolicyId) {
  mint(r: OracleMintAction, p: PolicyId, tx: Transaction) {
    expect [Pair(oName, oAmt)] =
      tx.mint
        |> tokens(p)
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
            fn(output) { output.address.payment_credential == Script(p) },
          )

        expect [Pair(tName, 1)] =
          out.value
            |> assets.tokens(p)
            |> dict.to_pairs()

        expect InlineDatum(datum) = out.datum
        expect oracleDatum: OracleDatum = datum

        expect Some(interest) =
          list.find(
            tx.outputs,
            fn(output) {
              output.address.payment_credential == Script(cDatum.interestVal)
            },
          )

        expect [Pair(iName, 1)] =
          interest.value
            |> assets.tokens(p)
            |> dict.to_pairs()

        expect InlineDatum(datum) = interest.datum
        expect interestDatum: InterestDatum = datum

        expect Some(supplyOut) =
          list.find(
            tx.outputs,
            fn(output) {
              output.address.payment_credential == Script(cDatum.supplyVal)
            },
          )

        expect InlineDatum(datum) = supplyOut.datum
        expect supplyDatum: SupplyDatum = datum

        and {
          oracleDatum.exchange == exchange,
          oracleDatum.timestamp == timestamp,
          oracleDatum.currency == currency,
          oracleDatum.supply == supply,
          oracleDatum.borrowed == borrowed,
          interestDatum.base == base,
          interestDatum.optimal == optimal,
          interestDatum.slope1 == slope1,
          interestDatum.slope2 == slope2,
          interestDatum.term == term,
          supplyDatum.policy == currency,
          supplyDatum.asset == "",
          oName == iName,
          oName == tName,
          list.has(tx.extra_signatories, o) && oAmt == 3,
        }
      }
      OBurn -> list.has(tx.extra_signatories, o) && oAmt == -3
    }
  }

  spend(
    datum: Option<OracleDatum>,
    r: OracleAction,
    ownRef: OutputReference,
    tx: Transaction,
  ) {
    expect Some(d) = datum
    expect Some(ownIn) =
      list.find(tx.inputs, fn(input) { input.output_reference == ownRef })
    expect Script(ownHash) = ownIn.output.address.payment_credential

    expect h.has_singleton_input(tx, ownRef)

    when r is {
      OracleUpdate { exchange, timestamp, supply, borrowed } -> {
        let out = h.get_own_singleton_output(tx, ownRef)

        expect [Pair(_, 1)] =
          assets.without_lovelace(out.value)
            |> assets.tokens(ownHash)
            |> dict.to_pairs()

        expect InlineDatum(datum) = out.datum
        expect datum: OracleDatum = datum

        and {
          list.has(tx.extra_signatories, o),
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
        expect Some(input) = transaction.find_input(tx.inputs, ownRef)

        expect [Pair(inName, 1)] =
          // get singleton name
          assets.without_lovelace(input.output.value)
            |> assets.tokens(ownHash)
            |> dict.to_pairs()

        expect [Pair(burnName, -3)] =
          tx.mint
            |> assets.tokens(ownHash)
            |> dict.to_pairs()

        list.has(tx.extra_signatories, o) && inName == burnName
      }
    }
  }

  else(_) {
    fail
  }
}
