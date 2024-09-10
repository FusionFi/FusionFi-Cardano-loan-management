use cardano/assets
use cardano/transaction.{InlineDatum, Transaction, placeholder}
use ori/merkel_config_validator
use tests/tools as t
// use tests/tools as t
use tests/transactions as tx

// use tests/transactions.{configActionUpdate, configDatum, oracleDatum}

//                        //
// Config Validator Tests //
//                        //

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
      ..placeholder,
      extra_signatories: [test_owner],
      inputs: [configInput],
      outputs: [configOutput],
    }

  merkel_config_validator.configVal.spend(
    test_owner,
    t.configMintHash,
    Some(configDatum),
    configAction,
    oref,
    tx,
  )?
}

test config_tokenSwap() {
  let vulnToken = assets.from_asset(t.configMintHash, #"1234", 1)

  let vulnOutputValue = assets.merge(assets.from_lovelace(2000000), vulnToken)

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
      ..placeholder,
      extra_signatories: [test_owner],
      inputs: [configInput],
      outputs: [configOutput],
    }

  trace @"VULNERABILITY"
  trace @"We can swap out configTokens with different names"
  merkel_config_validator.configVal.spend(
    test_owner,
    t.configMintHash,
    Some(configDatum),
    configAction,
    oref,
    tx,
  )?
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
      ..placeholder,
      extra_signatories: [#"dede"],
      inputs: [configInput],
      outputs: [configOutput],
    }

  merkel_config_validator.configVal.spend(
    test_owner,
    t.configMintHash,
    Some(configDatum),
    configAction,
    oref,
    tx,
  )?
}
