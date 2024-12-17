use aiken/collection/dict
use aiken/collection/list
use cardano/address.{Credential, Script}
use cardano/assets.{PolicyId}
use cardano/transaction.{Output, Transaction}
use ccfl/helpersv3 as h
use ccfl/types.{WithdrawRedeemer}
use ccfl/typesv3.{MerkelConfigDatum}

//                         //
// Supply Assets Validator //
//                         //

validator supply(cp: PolicyId, op: PolicyId) {
  withdraw(_r: WithdrawRedeemer, cred: Credential, tx: Transaction) {
    expect Script(_own_validator) = cred

    let cDatum: MerkelConfigDatum = h.get_config_datum(tx.reference_inputs, cp)

    let oracleIns =
      list.filter(
        tx.inputs,
        fn(input) {
          input.output.address.payment_credential == Script(op) && list.has(
            assets.policies(input.output.value),
            op,
          )
        },
      )

    let oracleOuts =
      list.filter(
        tx.outputs,
        fn(output) {
          output.address.payment_credential == Script(op) && list.has(
            assets.policies(output.value),
            op,
          )
        },
      )

    let (oracleIn, oIn, _oracleOut, oOut) = h.getOracleIO(oracleIns, oracleOuts)

    expect [Pair(oracleName, oracleQty)] =
      oracleIn
        |> assets.tokens(op)
        |> dict.to_pairs()

    expect [Pair(lpName, lpAmt)] =
      tx.mint
        |> assets.tokens(cDatum.supplyVal)
        |> dict.to_pairs()

    let supplyIns =
      list.filter(
        tx.inputs,
        fn(input) {
          input.output.address.payment_credential == Script(cDatum.supplyVal) && list.has(
            assets.policies(input.output.value),
            op,
          )
        },
      )

    let supplyOuts =
      list.filter(
        tx.outputs,
        fn(output) {
          output.address.payment_credential == Script(cDatum.supplyVal) && list.has(
            assets.policies(output.value),
            op,
          )
        },
      )

    // (Value, SupplyDatum, Value, SupplyDatum)
    let (supplyIn, sIn, supplyOut, sOut) =
      h.getSupplyIO(supplyIns, supplyOuts, op, oracleName, oracleQty)

    // merge lpAmt of supplyAsset to compare with supplyOut
    let newValue =
      assets.merge(supplyIn, assets.from_asset(sIn.policy, sIn.asset, lpAmt))

    and {
      lpName == sIn.policy,
      sIn.policy == sOut.policy,
      sIn.asset == sOut.asset,
      oOut.supply == oIn.supply + lpAmt,
      newValue == supplyOut,
    }
  }

  else(_) {
    fail
  }
}
