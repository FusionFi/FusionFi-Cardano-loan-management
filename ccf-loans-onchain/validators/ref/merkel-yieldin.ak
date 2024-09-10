use aiken/collection/list
use cardano/address.{Address, Credential, Script}
use cardano/assets.{PolicyId}
use cardano/transaction.{InlineDatum, Input, Output, Transaction}
use ccfl/helpers
use ccfl/types.{CollateralDatum, MerkelConfigDatum, WithdrawRedeemer}

validator yieldDeposit(cp: PolicyId) {
  withdraw(r: WithdrawRedeemer, _cred: Credential, tx: Transaction) {
    let cDatum: MerkelConfigDatum =
      helpers.get_config_datum(tx.reference_inputs, cp)

    helpers.merkelYield(
      tx.outputs,
      r.a,
      fn(collateral) {
        let loanToken = assets.without_lovelace(collateral.value)

        expect InlineDatum(datum) = collateral.datum
        expect outDatum: CollateralDatum = datum
        let outYield = outDatum.yield

        expect Some(colIn) =
          list.find(
            tx.inputs,
            fn(in) {
              in.output.address.payment_credential == collateral.address.payment_credential && assets.without_lovelace(
                in.output.value,
              ) == loanToken
            },
          )

        expect InlineDatum(datum) = colIn.output.datum
        expect inDatum: CollateralDatum = datum
        let inYield = inDatum.yield

        expect Some(_yieldOut) =
          list.find(
            tx.outputs,
            fn(out) {
              out.value == assets.from_lovelace(outYield - inYield) && out.address.payment_credential == Script(
                cDatum.yield,
              )
            },
          )

        and {
          outDatum.yield + assets.lovelace_of(collateral.value) == inDatum.yield + assets.lovelace_of(
            colIn.output.value,
          ),
          inDatum.yield < outDatum.yield,
        }
      },
    )
  }

  else(_) {
    fail
  }
}
