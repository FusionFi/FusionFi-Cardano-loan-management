use aiken/collection/list
use cardano/address.{Address, Credential, Script}
use cardano/assets.{PolicyId}
use cardano/transaction.{InlineDatum, Input, Output, Transaction}
use ccfl/helpers.{merkelYield}
use ccfl/types.{CollateralDatum, MerkelConfigDatum, WithdrawRedeemer}

// type CYieldDatum {
//   amount: Int,
//   timestamp: Int,
//   yield: Int,
// }

validator yieldWithdraw(cp: PolicyId) {
  withdraw(r: WithdrawRedeemer, _cred: Credential, tx: Transaction) {
    let Transaction { inputs, outputs, reference_inputs, .. } = tx

    expect Some(configIn) =
      list.find(
        reference_inputs,
        fn(input) { list.has(assets.policies(input.output.value), cp) },
      )

    expect InlineDatum(datum) = configIn.output.datum
    expect cDatum: MerkelConfigDatum = datum

    merkelYield(
      outputs,
      r.a,
      fn(collateral) {
        let loanToken = assets.without_lovelace(collateral.value)

        expect InlineDatum(datum) = collateral.datum
        expect outDatum: CollateralDatum = datum

        expect Some(colIn) =
          list.find(
            inputs,
            fn(in) {
              in.output.address.payment_credential == collateral.address.payment_credential && assets.without_lovelace(
                in.output.value,
              ) == loanToken
            },
          )

        expect InlineDatum(datum) = colIn.output.datum
        expect inDatum: CollateralDatum = datum

        expect Some(_yieldIn) =
          list.find(
            inputs,
            fn(in) {
              in.output.address.payment_credential == Script(cDatum.yield) && assets.lovelace_of(
                in.output.value,
              ) >= outDatum.yield - inDatum.yield
            },
          )

        outDatum.yield + assets.lovelace_of(collateral.value) == inDatum.yield + assets.lovelace_of(
          colIn.output.value,
        ) && inDatum.yield > outDatum.yield
      },
    )
  }

  else(_) {
    fail
  }
}
