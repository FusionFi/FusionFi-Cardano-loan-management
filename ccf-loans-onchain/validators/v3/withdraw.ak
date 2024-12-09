use aiken/collection/dict
use aiken/collection/list
use cardano/address.{Credential, Script}
use cardano/assets.{PolicyId}
use cardano/transaction.{InlineDatum, Output, Transaction}
use ccfl/helpers.{merkelBurn}
use ccfl/types.{CollateralDatum, LoanDatum, WithdrawRedeemer}

//                             //
// Supply Withdrawal Validator //
//                             //

pub type WithdrawAction {
  a: Int,
}

// this is an index of the user output so we can access it easily

validator withdraw(op: PolicyId) {
  withdraw(r: WithdrawAction, cred: Credential, tx: Transaction) {
    expect Script(_own_validator) = cred

    let cDatum: MerkelConfigDatum =
      helpers.get_config_datum(reference_inputs, cp)

    expect Some(oracleIns) =
      list.filter(
        tx.inputs,
        fn(input) {
          input.output.address.payment_credential == cDatum.oracleVal && list.has(
            assets.policies(input.output.value),
            op,
          )
        },
      )

    expect Some(oracleOuts) =
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

    expect Some(userOut) = list.index_of(tx.outputs, r.a)

    expect Some(userIns) =
      list.filter(
        tx.inputs,
        fn(input) {
          input.output.address.payment_credential == userOut.address.payment_credential
        },
      )

    let (userInValue, userOutValue) =
      helpers.getUserIO(userIns, userOut, cDatum.supplyVal)

    expect [Pair(inName, inAmt)] =
      userInValue
        |> assets.tokens(cDatum.supplyVal)
        |> dict.to_pairs()

    if inAmt > value {
      expect [Pair(outName, outAmt)] =
        userOutValue
          |> assets.tokens(cDatum.supplyVal)
          |> dict.to_pairs()

      and {
        outName == oOut.currency,
        outAmt == inAmt - value,
        lpName == oOut.currency,
        lpAmt == 0 - value,
        oIn.supply == oOut.supply + value,
        inName == oOut.currency,
      }
    } else if inAmt == value {
      and {
        lpName == sIn.policy,
        lpAmt == 0 - value,
        oIn.supply == oOut.supply + value,
        inName == oOut.currency,
      }
    } else {
      fail
    }
  }

  else(_) {
    fail
  }
}
