use aiken/collection/dict
use aiken/collection/list
use cardano/address.{Credential, Script}
use cardano/assets.{PolicyId}
use cardano/transaction.{InlineDatum, Output, Transaction}
use ccfl/helpers.{merkelBurn}
use ccfl/types.{CollateralDatum, LoanDatum, WithdrawRedeemer}

//                         //
// Supply Assets Validator //
//                         //

validator supply(op: PolicyId) {
  withdraw(r: WithdrawRedeemer, cred: Credential, tx: Transaction) {
    expect Script(_own_validator) = cred

    let cDatum: MerkelConfigDatum =
      helpers.get_config_datum(reference_inputs, cp)

    expect oracleIns =
      list.filter(
        tx.inputs,
        fn(input) {
          input.output.address.payment_credential == cDatum.oracleVal && list.has(
            assets.policies(input.output.value),
            op,
          )
        },
      )

    expect oracleOuts =
      list.filter(
        tx.outputs,
        fn(outputs) {
          output.address.payment_credential == cDatum.oracleVal && list.has(
            assets.policies(input.output.value),
            op,
          )
        },
      )

    let (oracleIn, oIn, oracleOut, oOut) =
      helpers.getOracleIO(oracleIns, oracleOuts)

    expect [Pair(oracleName, oracleQty)] =
      oracleIn
        |> assets.tokens(op)
        |> dict.to_pairs()

    expect [Pair(lpName, lpAmt)] =
      tx.mint
        |> assets.tokens(cDatum.supplyVal)
        |> dict.to_pairs()

    expect supplyIns =
      list.filter(
        tx.inputs,
        fn(inputs) {
          input.output.address.payment_credential == cDatum.supplyVal && list.has(
            assets.policies(input.output.value),
            op,
          )
        },
      )

    expect supplyOuts =
      list.filter(
        tx.outputs,
        fn(inputs) {
          output.address.payment_credential == cDatum.supplyVal && list.has(
            assets.policies(input.output.value),
            op,
          )
        },
      )

    // (Value, SupplyDatum, Value, SupplyDatum)
    let (supplyIn, sIn, supplyOut, sOut) =
      helpers.getSupplyIO(supplyIns, supplyOuts, op, oracleName, oracleQty)

    // merge lpAmt of supplyAsset to compare with supplyOut
    expect newValue =
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
