use cardano/address.{Script}
use cardano/assets
use cardano/transaction.{Transaction, placeholder}
use tests/tools as t
use tests/transactions as tx
use v1/merkel_balance

//                         //
// Balance Validator Tests //
//                         //

test merkel_balance_single() {
  let inRatio = 1000
  let outRatio = 1000

  let inLoanAmount = 1000
  let inCollateralAmount = 2000
  let inCollateralValue = 2000

  let outLoanAmount = 1000
  let outCollateralAmount = 2000
  let outCollateralValue = 4000

  let test_owner = #"face"

  // withdrawl
  let withdraw0 = tx.withdrawal(t.merkelBalance)

  let bRedeemer = tx.withdrawRedeemer([0])

  let loanIn1 = tx.mLoanInput(1, inLoanAmount)
  let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue, 0)

  let userIn1 = tx.userInput(2024)
  let configIn = tx.configInput()
  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let loanOut1 = tx.mLoanOutput(outLoanAmount)
  let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue, 0)

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [colIn1, loanIn1, oracleIn, userIn1],
      outputs: [colOut1, loanOut1, oracleOut],
      withdrawals: withdraw0,
    }

  merkel_balance.balance.withdraw(
    t.oracleMintHash,
    t.configMintHash,
    bRedeemer,
    Script(t.merkelBalance),
    tx,
  )?
}

test balance_colAmtFail() {
  let inRatio = 1000
  let outRatio = 1000

  let inLoanAmount = 1000
  let inCollateralAmount = 2000
  let inCollateralValue = 2000

  let outLoanAmount = 1000
  let outCollateralAmount = 100
  let outCollateralValue = 4000

  let test_owner = #"face"

  // withdrawl
  let withdraw0 = tx.withdrawal(t.merkelBalance)

  let bRedeemer = tx.withdrawRedeemer([0])

  let loanIn1 = tx.mLoanInput(1, inLoanAmount)
  let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue, 0)

  let userIn1 = tx.userInput(2024)
  let configIn = tx.configInput()
  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let loanOut1 = tx.mLoanOutput(outLoanAmount)
  let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue, 0)

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [colIn1, loanIn1, oracleIn, userIn1],
      outputs: [colOut1, loanOut1, oracleOut],
      withdrawals: withdraw0,
    }

  trace @"VULNERABILITY"
  trace @"Vou can change the collateralDatum Amount"

  merkel_balance.balance.withdraw(
    t.oracleMintHash,
    t.configMintHash,
    bRedeemer,
    Script(t.merkelBalance),
    tx,
  )?
}

test balance_colValueFail() fail {
  let inRatio = 1000
  let outRatio = 1000

  let inLoanAmount = 1000
  let inCollateralAmount = 2000
  let inCollateralValue = 2000

  let outLoanAmount = 1000
  let outCollateralAmount = 2000
  let outCollateralValue = 500

  let test_owner = #"face"

  // withdrawl
  let withdraw0 = tx.withdrawal(t.merkelBalance)

  let bRedeemer = tx.withdrawRedeemer([0])

  let loanIn1 = tx.mLoanInput(1, inLoanAmount)
  let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue, 0)

  let userIn1 = tx.userInput(2024)
  let configIn = tx.configInput()
  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let loanOut1 = tx.mLoanOutput(outLoanAmount)
  let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue, 0)

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [colIn1, loanIn1, oracleIn, userIn1],
      outputs: [colOut1, loanOut1, oracleOut],
      withdrawals: withdraw0,
    }

  merkel_balance.balance.withdraw(
    t.oracleMintHash,
    t.configMintHash,
    bRedeemer,
    Script(t.merkelBalance),
    tx,
  )?
}

test balance_loanAmountFail() fail {
  let inRatio = 1000
  let outRatio = 1000

  let inLoanAmount = 1000
  let inCollateralAmount = 2000
  let inCollateralValue = 2000

  let outLoanAmount = 500
  let outCollateralAmount = 1000
  let outCollateralValue = 1000

  let test_owner = #"face"

  // withdrawl
  let withdraw0 = tx.withdrawal(t.merkelBalance)

  let bRedeemer = tx.withdrawRedeemer([0])

  let loanIn1 = tx.mLoanInput(1, inLoanAmount)
  let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue, 0)

  let userIn1 = tx.userInput(2024)
  let configIn = tx.configInput()
  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let loanOut1 = tx.mLoanOutput(outLoanAmount)
  let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue, 0)

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [colIn1, loanIn1, oracleIn, userIn1],
      outputs: [colOut1, loanOut1, oracleOut],
      withdrawals: withdraw0,
    }

  merkel_balance.balance.withdraw(
    t.oracleMintHash,
    t.configMintHash,
    bRedeemer,
    Script(t.merkelBalance),
    tx,
  )?
}

test balance_tokenSwap() fail {
  let inRatio = 1000
  let outRatio = 1000

  let inLoanAmount = 1000
  let inCollateralAmount = 2000
  let inCollateralValue = 2000

  let outLoanAmount = 1000
  let outCollateralAmount = 2000
  let outCollateralValue = 4000

  let vulnToken = assets.from_asset(t.loanMintHash, #"deaf", 1)

  let test_owner = #"face"

  // withdrawl
  let withdraw0 = tx.withdrawal(t.merkelBalance)

  let bRedeemer = tx.withdrawRedeemer([0])

  let loanIn1 = tx.mLoanInput(1, inLoanAmount)
  let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue, 0)

  let userIn1 = tx.userInput(2024)
  let configIn = tx.configInput()
  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let loanOut1 =
    t.test_output(
      t.test_script_address(t.mLoan),
      assets.merge(assets.from_lovelace(2000000), vulnToken),
      tx.loanOutDatum(outLoanAmount),
    )

  let colOut1 =
    t.test_output(
      t.test_script_address(t.mCol),
      assets.merge(assets.from_lovelace(outCollateralValue), vulnToken),
      tx.collateralDatumOut(outCollateralAmount, 0),
    )

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [colIn1, loanIn1, oracleIn, userIn1],
      outputs: [colOut1, loanOut1, oracleOut],
      withdrawals: withdraw0,
    }

  merkel_balance.balance.withdraw(
    t.oracleMintHash,
    t.configMintHash,
    bRedeemer,
    Script(t.merkelBalance),
    tx,
  )?
}

test balance_oracleSwap() fail {
  let vulnToken = assets.from_asset(t.oracleMintHash, #"1234", 1)

  let vulnOracleValue = assets.merge(assets.from_lovelace(2000000), vulnToken)
  let inRatio = 1000
  let outRatio = 1000

  let inLoanAmount = 1000
  let inCollateralAmount = 2000
  let inCollateralValue = 2000

  let outLoanAmount = 1000
  let outCollateralAmount = 2000
  let outCollateralValue = 4000

  let test_owner = #"face"

  // withdrawl
  let withdraw0 = tx.withdrawal(t.merkelBalance)

  let bRedeemer = tx.withdrawRedeemer([0])

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

  let loanOut1 = tx.mLoanOutput(outLoanAmount)
  let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue, 0)

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [colIn1, loanIn1, oracleIn, userIn1],
      outputs: [colOut1, loanOut1, oracleOut],
      withdrawals: withdraw0,
    }

  merkel_balance.balance.withdraw(
    t.oracleMintHash,
    t.configMintHash,
    bRedeemer,
    Script(t.merkelBalance),
    tx,
  )?
}

test balance_ratioFail() fail {
  let inRatio = 1000
  let outRatio = 900

  let inLoanAmount = 1000
  let inCollateralAmount = 2000
  let inCollateralValue = 2000

  let outLoanAmount = 1000
  let outCollateralAmount = 2000
  let outCollateralValue = 2000

  let test_owner = #"face"

  // withdrawl
  let withdraw0 = tx.withdrawal(t.merkelBalance)

  let bRedeemer = tx.withdrawRedeemer([0])

  let loanIn1 = tx.mLoanInput(1, inLoanAmount)
  let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue, 0)

  let userIn1 = tx.userInput(2024)
  let configIn = tx.configInput()
  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let loanOut1 = tx.mLoanOutput(outLoanAmount)
  let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue, 0)

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [colIn1, loanIn1, oracleIn, userIn1],
      outputs: [colOut1, loanOut1, oracleOut],
      withdrawals: withdraw0,
    }

  merkel_balance.balance.withdraw(
    t.oracleMintHash,
    t.configMintHash,
    bRedeemer,
    Script(t.merkelBalance),
    tx,
  )?
}
