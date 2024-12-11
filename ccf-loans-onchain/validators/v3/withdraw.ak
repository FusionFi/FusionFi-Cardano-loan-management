use aiken/collection/dict
use aiken/collection/list
use cardano/address.{Credential, Script}
use cardano/assets.{PolicyId}
use cardano/transaction.{Output, Transaction}
use ccfl/helpersv3 as h
use ccfl/typesv3.{MerkelConfigDatum}

//                             //
// Supply Withdrawal Validator //
//                             //

pub type WithdrawAction {
  a: Int,
  value: Int,
}

// this is an index of the user output so we can access it easily

validator withdraw(cp: PolicyId, op: PolicyId) {
  withdraw(r: WithdrawAction, cred: Credential, tx: Transaction) {
    expect Script(_own_validator) = cred

    let cDatum: MerkelConfigDatum = h.get_config_datum(tx.reference_inputs, cp)

    let oracleIns =
      list.filter(
        tx.inputs,
        fn(input) {
          input.output.address.payment_credential == Script(cDatum.oracleVal) && list.has(
            assets.policies(input.output.value),
            op,
          )
        },
      )

    let oracleOuts =
      list.filter(
        tx.outputs,
        fn(output) {
          output.address.payment_credential == Script(cDatum.oracleVal) && list.has(
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

    expect Some(userOut) = list.at(tx.outputs, r.a)

    let userIns =
      list.filter(
        tx.inputs,
        fn(input) {
          input.output.address.payment_credential == userOut.address.payment_credential
        },
      )

    let (userInValue, userOutValue) =
      h.getUserIO(userIns, userOut, cDatum.supplyVal)

    expect [Pair(inName, inAmt)] =
      userInValue
        |> assets.tokens(cDatum.supplyVal)
        |> dict.to_pairs()

    if inAmt > r.value {
      expect [Pair(outName, outAmt)] =
        userOutValue
          |> assets.tokens(cDatum.supplyVal)
          |> dict.to_pairs()

      and {
        outName == oOut.currency,
        outAmt == inAmt - r.value,
        lpName == oOut.currency,
        lpAmt == 0 - r.value,
        oIn.supply == oOut.supply + r.value,
        inName == oOut.currency,
        sOut == sIn,
        supplyIn == assets.merge(
          supplyOut,
          assets.from_asset(sIn.policy, sIn.asset, r.value),
        ),
      }
    } else if inAmt == r.value {
      and {
        (lpName == sIn.policy)?,
        (lpAmt == 0 - r.value)?,
        (oIn.supply == oOut.supply + r.value)?,
        (inName == oOut.currency)?,
        (sOut == sIn)?,
        (supplyIn == assets.merge(
          supplyOut,
          assets.from_asset(sIn.policy, sIn.asset, r.value),
        ))?,
      }
    } else {
      fail
    }
  }

  else(_) {
    fail
  }
}
