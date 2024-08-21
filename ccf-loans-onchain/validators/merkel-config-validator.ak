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
// use tests/tools as t
use tests/tools as t
use tests/transactions as tx

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
        interestVal,
        collateralRedeemers,
      } -> {
        // gets own output (ensures there is only one)
        let ownOut = get_own_singleton_output(transaction, oref)
        // checks output datum
        expect InlineDatum(datum) = ownOut.datum
        expect outDatum: MerkelConfigDatum = datum
        // checks signed by owner, has a Config Token Datum values match redeemer
        has(extra_signatories, o) && has(policies(ownOut.value), cp) && outDatum.loanVal == loanVal && outDatum.colVal == colVal && outDatum.rewardsVal == rewardsVal && outDatum.oracleVal == oracleVal && outDatum.interestVal == interestVal && outDatum.collateralRedeemers == collateralRedeemers
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
      t.interestValHash,
      t.collateralRedeemers(),
    )

  let configDatum =
    tx.mConfigDatum(
      t.mLoan,
      t.mCol,
      t.rewardsMintHash,
      t.oracleValHash,
      t.interestValHash,
      #"bebe",
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

test config_tokenSwap() {
  let vulnToken = value.from_asset(t.configMintHash, #"1234", 1)

  let vulnOutputValue = value.merge(value.from_lovelace(2000000), vulnToken)

  let test_owner = #"face"

  let oref = tx.oref(#"cece", 1)

  let configAction =
    tx.mConUpdate(
      t.mLoan,
      t.mCol,
      t.rewardsMintHash,
      t.oracleValHash,
      t.interestValHash,
      t.collateralRedeemers(),
    )

  let configDatum =
    tx.mConfigDatum(
      t.mLoan,
      t.mCol,
      t.rewardsMintHash,
      t.oracleValHash,
      t.interestValHash,
      #"bebe",
      t.collateralRedeemers(),
    )

  let configInput = tx.configInput()

  let configOutput =
    t.test_output(
      t.test_script_address(t.merkelConfigHash),
      vulnOutputValue,
      InlineDatum(configDatum),
    )

  let tx =
    Transaction {
      ..placeholder(),
      extra_signatories: [test_owner],
      inputs: [configInput],
      outputs: [configOutput],
    }

  let ctx = ScriptContext { purpose: Spend(oref), transaction: tx }

  trace @"VULNERABILITY"
  trace @"We can swap out configTokens with different names"
  configVal(test_owner, t.configMintHash, configDatum, configAction, ctx)?
}

test config_sigFail() fail {
  let test_owner = #"face"

  let oref = tx.oref(#"cece", 1)

  let configAction =
    tx.mConUpdate(
      t.mLoan,
      t.mCol,
      t.rewardsMintHash,
      t.oracleValHash,
      t.interestValHash,
      t.collateralRedeemers(),
    )

  let configDatum =
    tx.mConfigDatum(
      t.mLoan,
      t.mCol,
      t.rewardsMintHash,
      t.oracleValHash,
      t.interestValHash,
      #"bebe",
      t.collateralRedeemers(),
    )

  let configInput = tx.configInput()

  let configOutput = tx.configOutput(configDatum)

  let tx =
    Transaction {
      ..placeholder(),
      extra_signatories: [#"dede"],
      inputs: [configInput],
      outputs: [configOutput],
    }

  let ctx = ScriptContext { purpose: Spend(oref), transaction: tx }

  configVal(test_owner, t.configMintHash, configDatum, configAction, ctx)?
}
