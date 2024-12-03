use cardano/address.{Script}
use cardano/assets
use cardano/transaction.{NoDatum, Transaction, placeholder}
use ori/merkel_close
use tests/tools as t
use tests/transactions as tx

//                       //
// Close Validator Tests //
//                       //

test merkel_close_single() {
  let inRatio = 1000
  let outRatio = 1000

  let inLoanAmount = 0
  let inCollateralAmount = 0
  let inCollateralValue = 2

  let test_owner = #"face"

  // let configDatum = tx.configDatumIn()
  let withdraw0 = tx.withdrawal(t.merkelClose)

  let loanIn1 = tx.mLoanInput(1, inLoanAmount)
  let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue, 0)
  let userIn1 = tx.userInput(2024)

  let configIn = tx.configInput()

  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let redeemerList = tx.withdrawRedeemer([0])

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [loanIn1, oracleIn, userIn1, colIn1],
      outputs: [oracleOut],
      mint: t.loanBurnValue(),
      withdrawals: withdraw0,
    }

  merkel_close.close.withdraw(
    t.loanMintHash,
    t.oracleMintHash,
    redeemerList,
    Script(t.merkelClose),
    tx,
  )?
}

test close_colValueFail() fail {
  let inRatio = 1000
  let outRatio = 1000

  let inLoanAmount = 0
  let inCollateralAmount = 10
  let inCollateralValue = 2

  let test_owner = #"face"

  // let configDatum = tx.configDatumIn()
  let withdraw0 = tx.withdrawal(t.merkelClose)

  let loanIn1 = tx.mLoanInput(1, inLoanAmount)
  let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue, 0)
  let userIn1 = tx.userInput(2024)

  let configIn = tx.configInput()

  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let redeemerList = tx.withdrawRedeemer([0])

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [loanIn1, oracleIn, userIn1, colIn1],
      outputs: [oracleOut],
      mint: t.loanBurnValue(),
      withdrawals: withdraw0,
    }

  merkel_close.close.withdraw(
    t.loanMintHash,
    t.oracleMintHash,
    redeemerList,
    Script(t.merkelClose),
    tx,
  )?
}

test close_loanAmtFail() fail {
  let inRatio = 1000
  let outRatio = 1000

  let inLoanAmount = 10
  let inCollateralAmount = 0
  let inCollateralValue = 2

  let test_owner = #"face"

  // let configDatum = tx.configDatumIn()
  let withdraw0 = tx.withdrawal(t.merkelClose)

  let loanIn1 = tx.mLoanInput(1, inLoanAmount)
  let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue, 0)
  let userIn1 = tx.userInput(2024)

  let configIn = tx.configInput()

  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let redeemerList = tx.withdrawRedeemer([0])

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [loanIn1, oracleIn, userIn1, colIn1],
      outputs: [oracleOut],
      mint: t.loanBurnValue(),
      withdrawals: withdraw0,
    }

  merkel_close.close.withdraw(
    t.loanMintHash,
    t.oracleMintHash,
    redeemerList,
    Script(t.merkelClose),
    tx,
  )?
}

test close_tokenSwap() fail {
  let vulnToken = assets.from_asset(t.loanMintHash, #"dede", -2)

  let inRatio = 1000
  let outRatio = 1000

  let inLoanAmount = 0
  let inCollateralAmount = 0
  let inCollateralValue = 2

  let test_owner = #"face"

  // let configDatum = tx.configDatumIn()
  let withdraw0 = tx.withdrawal(t.merkelClose)

  let loanIn1 = tx.mLoanInput(1, inLoanAmount)
  let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue, 0)
  let userIn1 = tx.userInput(2024)

  let configIn = tx.configInput()

  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let redeemerList = tx.withdrawRedeemer([0])

  let vulnOut =
    t.test_output(
      t.test_address(#"cafe"),
      assets.merge(t.loanTokenValue(), t.loanTokenValue()),
      NoDatum,
    )

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [loanIn1, oracleIn, userIn1, colIn1],
      outputs: [oracleOut, vulnOut],
      mint: vulnToken,
      withdrawals: withdraw0,
    }

  merkel_close.close.withdraw(
    t.loanMintHash,
    t.oracleMintHash,
    redeemerList,
    Script(t.merkelClose),
    tx,
  )?
}

test close_oracleSwap() {
  let vulnToken = assets.from_asset(t.oracleMintHash, #"1234", 1)

  let vulnOracleValue = assets.merge(assets.from_lovelace(2000000), vulnToken)

  let inRatio = 1000
  let outRatio = 1000

  let inLoanAmount = 0
  let inCollateralAmount = 0
  let inCollateralValue = 2

  let test_owner = #"face"

  // let configDatum = tx.configDatumIn()
  let withdraw0 = tx.withdrawal(t.merkelClose)

  let loanIn1 = tx.mLoanInput(1, inLoanAmount)
  let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue, 0)
  let userIn1 = tx.userInput(2024)

  let configIn = tx.configInput()

  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      vulnOracleValue,
      tx.oracleOutDatum(outRatio),
    )

  let redeemerList = tx.withdrawRedeemer([0])

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [loanIn1, oracleIn, userIn1, colIn1],
      outputs: [oracleOut],
      mint: t.loanBurnValue(),
      withdrawals: withdraw0,
    }

  trace @"VULNERABILITY"
  trace @"Allows to swap oracle token output"
  merkel_close.close.withdraw(
    t.loanMintHash,
    t.oracleMintHash,
    redeemerList,
    Script(t.merkelClose),
    tx,
  )?
}
