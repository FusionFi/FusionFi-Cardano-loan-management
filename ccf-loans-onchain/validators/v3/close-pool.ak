use aiken/collection/dict
use aiken/collection/list
use cardano/address.{Credential, Script}
use cardano/assets.{PolicyId}
use cardano/transaction.{InlineDatum, Output, Transaction}
use ccfl/helpersv3 as h
use ccfl/typesv3.{MerkelConfigDatum, OracleDatum, SupplyDatum}

//                        //
// Merkel Close Validator //
//                        //

pub type CloseWithdraw {
  asset: ByteArray,
}

validator close(cp: PolicyId, op: PolicyId) {
  withdraw(r: CloseWithdraw, cred: Credential, tx: Transaction) {
    expect Script(_own_validator) = cred

    let cDatum: MerkelConfigDatum = h.get_config_datum(tx.reference_inputs, cp)

    expect [Pair(oName, oAmt)] =
      tx.mint
        |> assets.tokens(op)
        |> dict.to_pairs()

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
    expect 1 = list.length(oracleIns)
    expect Some(oracleIn) = list.head(oracleIns)

    expect InlineDatum(datum) = oracleIn.output.datum
    expect oIn: OracleDatum = datum

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
    expect 1 = list.length(supplyIns)
    expect Some(in) = list.head(supplyIns)

    expect InlineDatum(datum) = in.output.datum
    expect d: SupplyDatum = datum

    let tokenValue = assets.quantity_of(in.output.value, d.policy, d.asset)

    and {
      tokenValue == 0,
      oIn.borrowed == 0,
      oIn.supply == 0,
      oAmt == -3,
      oName == r.asset,
    }
  }

  else(_) {
    fail
  }
}
