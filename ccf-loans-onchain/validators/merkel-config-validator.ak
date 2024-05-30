use aiken/list.{has}
use aiken/transaction.{
  InlineDatum, Output, ScriptContext, Spend, Transaction, placeholder,
}
use aiken/transaction/value.{PolicyId, policies}
use ccfl/helpers.{get_own_singleton_output}
use ccfl/types.{
  MConClose, MConUpdate, MerkelConfigAction, MerkelConfigDatum,
  VerificationKeyHash,
}
use tests/tools as t
use tests/transactions as tx

// use tests/tools as t
// use tests/transactions.{configActionUpdate, configDatum, oracleDatum}

//                         //
// Merkel Config Validator //
//                         //

validator(o: VerificationKeyHash, cp: PolicyId) {
  fn configVal(
    _d: MerkelConfigDatum,
    r: MerkelConfigAction,
    c: ScriptContext,
  ) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Spend(oref) = purpose

    let Transaction { extra_signatories, .. } = transaction

    when r is {
      MConUpdate {
        loanVal,
        colVal,
        rewardsVal,
        oracleVal,
        loanRedeemers,
        collateralRedeemers,
      } -> {
        // gets own output (ensures there is only one)
        let ownOut = get_own_singleton_output(transaction, oref)
        // checks output datum
        expect InlineDatum(datum) = ownOut.datum
        expect outDatum: MerkelConfigDatum = datum
        // checks signed by owner, has a Config Token Datum values match redeemer
        has(extra_signatories, o) && has(policies(ownOut.value), cp) && outDatum.loanVal == loanVal && outDatum.colVal == colVal && outDatum.rewardsVal == rewardsVal && outDatum.oracleVal == oracleVal && outDatum.loanRedeemers == loanRedeemers && outDatum.collateralRedeemers == collateralRedeemers
      }
      // checks signed by owner
      MConClose -> has(extra_signatories, o)
    }
  }
}

//                  //
// Config Val Tests //
//                  //

test config_val() {
  let test_owner = #"face"

  let oref = tx.oref(#"cece", 1)

  let configAction =
    tx.mConUpdate(
      t.mLoan,
      t.mCol,
      t.rewardsMintHash,
      t.oracleValHash,
      t.loanRedeemers(),
      t.collateralRedeemers(),
    )

  let configDatum =
    tx.mConfigDatum(
      t.mLoan,
      t.mCol,
      t.rewardsMintHash,
      t.oracleValHash,
      t.loanRedeemers(),
      t.collateralRedeemers(),
    )

  let configInput = tx.configInput()

  let configOutput = tx.configOutput(configDatum)

  let tx =
    Transaction {
      ..placeholder(),
      extra_signatories: [test_owner],
      inputs: [configInput],
      outputs: [configOutput],
    }

  let ctx = ScriptContext { purpose: Spend(oref), transaction: tx }

  configVal(test_owner, t.configMintHash, configDatum, configAction, ctx)?
}
// test config_val_token_fail() fail {
//   let test_owner = #"face"

//   let oref = t.test_oref(#"face", 1)

//   let configAction =
//     configActionUpdate(t.loanValHash, t.collateralValHash, t.rewardsMintHash)

//   let configDatum1 =
//     configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
//   let inDatum = InlineDatum(configDatum1)
//   let outDatum = InlineDatum(configDatum1)

//   let configInput =
//     t.test_input(
//       oref,
//       t.test_output(
//         t.test_script_address(t.configValHash),
//         t.makeAdaValue(10),
//         // we dont check for a token input
//         inDatum,
//       ),
//     )

//   let configOutput =
//     t.test_output(
//       t.test_script_address(t.configValHash),
//       t.makeAdaValue(10),
//       // this only fails because there is no token output
//       outDatum,
//     )

//   let tx =
//     Transaction {
//       ..placeholder(),
//       extra_signatories: [test_owner],
//       inputs: [configInput],
//       outputs: [configOutput],
//     }

//   let ctx = ScriptContext { purpose: Spend(oref), transaction: tx }

//   configVal(test_owner, t.configMintHash, configDatum1, configAction, ctx)?
// }

// test config_val_datum_fail() fail {
//   let test_owner = #"face"

//   let oref = t.test_oref(#"face", 1)

//   let configAction =
//     configActionUpdate(t.loanValHash, t.collateralValHash, t.rewardsMintHash)

//   let configDatum1 =
//     configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)

//   let oracleDatum = oracleDatum(1, 1111111111, 1, 1)

//   let inDatum = InlineDatum(configDatum1)
//   let outDatum = InlineDatum(oracleDatum)

//   let configInput =
//     t.test_input(
//       oref,
//       t.test_output(
//         t.test_script_address(t.configValHash),
//         t.configValue(),
//         inDatum,
//       ),
//     )

//   let configOutput =
//     t.test_output(
//       t.test_script_address(t.configValHash),
//       t.configValue(),
//       outDatum,
//     )

//   let tx =
//     Transaction {
//       ..placeholder(),
//       extra_signatories: [test_owner],
//       inputs: [configInput],
//       outputs: [configOutput],
//     }

//   let ctx = ScriptContext { purpose: Spend(oref), transaction: tx }

//   configVal(test_owner, t.configMintHash, configDatum1, configAction, ctx)?
// }

// test config_val_sig_fail() fail {
//   let test_owner = #"face"

//   let oref = t.test_oref(#"face", 1)

//   let configAction =
//     configActionUpdate(t.loanValHash, t.collateralValHash, t.rewardsMintHash)

//   let configDatum1 =
//     configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
//   let inDatum = InlineDatum(configDatum1)
//   let outDatum = InlineDatum(configDatum1)

//   let configInput =
//     t.test_input(
//       oref,
//       t.test_output(
//         t.test_script_address(t.configValHash),
//         t.configValue(),
//         inDatum,
//       ),
//     )

//   let configOutput =
//     t.test_output(
//       t.test_script_address(t.configValHash),
//       t.configValue(),
//       outDatum,
//     )

//   let tx =
//     Transaction {
//       ..placeholder(),
//       extra_signatories: [#"cafe"],
//       inputs: [configInput],
//       outputs: [configOutput],
//     }

//   let ctx = ScriptContext { purpose: Spend(oref), transaction: tx }

//   configVal(test_owner, t.configMintHash, configDatum1, configAction, ctx)?
// }
