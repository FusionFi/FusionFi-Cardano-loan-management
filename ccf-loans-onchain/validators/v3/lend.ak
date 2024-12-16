use aiken/collection/dict
use aiken/collection/list
use cardano/address.{Credential, Script}
use cardano/assets.{PolicyId}
use cardano/transaction.{InlineDatum, Transaction}
use ccfl/helpersv3 as h
use ccfl/typesv3.{LoanDatum, MerkelConfigDatum}

//                               //
// Lending From Supply Validator //
//                               //

// This validator only gets uped when lending assets from the supply pools, not fiat.
// It has been made separate to loan minting but relies on it, and may need to take 
// a more controlling role in the future to manage fiat in the future.

pub type WithdrawAction {
  a: Int,
  value: Int,
}

validator lend(cp: PolicyId, op: PolicyId) {
  withdraw(r: WithdrawAction, cred: Credential, tx: Transaction) {
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

    let (oracleIn, oIn, oracleOut, oOut) = h.getOracleIO(oracleIns, oracleOuts)

    expect [Pair(oracleName, oracleQty)] =
      oracleOut
        |> assets.tokens(op)
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

    let newValue =
      assets.merge(
        supplyIn,
        assets.from_asset(sIn.policy, sIn.asset, 0 - r.value),
      )

    expect Some(loanOut) =
      list.find(
        tx.outputs,
        // need to access loanHash from ConfigDatum OR Params
        fn(output) {
          output.address.payment_credential == Script(cDatum.loanVal)
        },
      )

    expect [Pair(_lOutName, lOutAmt)] =
      loanOut.value
        |> assets.tokens(cDatum.loanVal)
        |> dict.to_pairs()

    expect InlineDatum(datum) = loanOut.datum
    expect lDatum: LoanDatum = datum

    // expect Some(userOut) =
    //   list.find(
    //     tx.outputs,
    //     fn(output) { output.address.payment_credential == lDatum.user },
    //   )
    and {
      assets.without_lovelace(oracleIn) == assets.without_lovelace(oracleOut),
      sIn == sOut,
      supplyOut == newValue,
      oOut.borrowed == oIn.borrowed + r.value,
      lDatum.amount == r.value,
      lOutAmt == 1,
    }
  }

  else(_) {
    fail
  }
}
