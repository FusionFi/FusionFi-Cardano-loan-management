// use cardano/assets
use cardano/transaction.{Transaction, placeholder}
use tests/tools as t
// use tests/tools as t
use tests/transactions as tx
use v1/merkel_config_validator

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
