use aiken/collection/dict
use aiken/collection/list
use aiken/collection/pairs
use cardano/address.{Script}
use cardano/assets.{PolicyId}
use cardano/transaction.{InlineDatum, OutputReference, Transaction}
use ccfl/helpersv3 as h
use ccfl/typesv3.{
  LPBurn, LPMint, MSupplyAction, MerkelConfigDatum, OracleDatum, SupplyDatum,
  SupplyMintAction,
}

// Supply Pool V2 //

// INCOMPLETE! //

// in order to allow people to supply their own assets for lending, we need to 
// create a pool for users to supply to, but in order to do that we will need to 
// track an individuals contributions and allow them to manage their value at any 
// given point
// we could have a system where users add to a single utxo, but that might affect 
// tracking rewards, making that a little complicated
// we could use a more complex design pattern like a linked list
// for now we will use a single thread, and we will need to implement chaining

// V2

// V2 contains its own oracle Token to make it easy to track and find the supply UTxO
validator supplyPool(_owner: ByteArray, op: PolicyId, cp: PolicyId) {
  mint(r: SupplyMintAction, p: PolicyId, tx: Transaction) {
    // only mints single asset class with token name that matches the supply policy
    expect [Pair(lpName, lpAmt)] =
      tx.mint
        |> assets.tokens(p)
        |> dict.to_pairs()

    // requires an input present to add to
    expect Some(ownInput) =
      list.find(
        tx.inputs,
        fn(input) {
          input.output.address.payment_credential == Script(p) && list.has(
            assets.policies(input.output.value),
            op,
          )
        },
      )

    let ownOracle =
      ownInput.output.value
        |> assets.tokens(p)

    expect Some(ownOutput) =
      list.find(
        tx.outputs,
        fn(output) {
          output.address.payment_credential == Script(p) && list.has(
            assets.policies(output.value),
            op,
          )
        },
      )

    expect ownOracle == ( ownOutput.value |> assets.tokens(p) )

    expect Some(oracleIn) =
      list.find(
        tx.inputs,
        fn(input) { list.has(assets.policies(input.output.value), op) },
      )
    expect ownOracle == ( oracleIn.output.value |> assets.tokens(p) )

    expect InlineDatum(datum) = oracleIn.output.datum
    expect oIn: OracleDatum = datum

    expect Some(oracleOut) =
      list.find(
        tx.outputs,
        fn(output) { output.address == oracleIn.output.address },
      )

    expect ownOracle == ( oracleOut.value |> assets.tokens(p) )

    expect InlineDatum(datum) = oracleOut.datum
    expect oOut: OracleDatum = datum

    when r is {
      LPMint { value } -> and {
          lpName == oIn.currency,
          lpAmt == value,
          oOut.supply == oIn.supply + value,
        }
      LPBurn -> and {
          lpName == oIn.currency,
          lpAmt == oOut.supply - oIn.supply,
        }
    }
  }

  spend(
    _datum: Option<SupplyDatum>,
    r: MSupplyAction,
    _oref: OutputReference,
    tx: Transaction,
  ) {
    let cDatum: MerkelConfigDatum = h.get_config_datum(tx.reference_inputs, cp)

    expect Some(stakeVal) =
      cDatum.supplyRedeemers
        |> list.at(r.i)

    pairs.has_key(tx.withdrawals, Script(stakeVal))
    // has no tokens in pool
    // oracle is burned
  }

  else(_) {
    fail
  }
}
