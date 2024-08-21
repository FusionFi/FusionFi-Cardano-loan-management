use aiken/list
use aiken/transaction.{
  InlineDatum, Input, Output, ScriptContext, Transaction, WithdrawFrom,
  placeholder,
}
// use aiken/transaction/credential
use aiken/transaction/value.{PolicyId}
use ccfl/helpers.{merkelTx}
use ccfl/types.{
  CollateralDatum, LoanDatum, MerkelConfigDatum, OracleDatum, WithdrawRedeemer,
}
use tests/tools as t
use tests/transactions as tx

// staking validators that check the full transaction scope.

// Merkel Balance validates the whole transaction for the Balance redeemer case
// it combines both the merkel-loan && merkel-collateral cases together

validator(p: PolicyId, cp: PolicyId) {
  fn balance(r: WithdrawRedeemer, c: ScriptContext) {
    // True
    expect ScriptContext {
      transaction,
      purpose: WithdrawFrom(_stake_credential),
    } = c

    let Transaction { inputs, outputs, reference_inputs, .. } = transaction

    expect Some(oracleOut) =
      list.find(
        outputs,
        fn(output) { list.has(value.policies(output.value), p) },
      )

    expect InlineDatum(datum) = oracleOut.datum
    expect rDatum: OracleDatum = datum

    let exchangeRate = rDatum.exchange

    expect Some(configIn) =
      list.find(
        reference_inputs,
        fn(input) { list.has(value.policies(input.output.value), cp) },
      )

    expect InlineDatum(datum) = configIn.output.datum
    expect _cDatum: MerkelConfigDatum = datum

    merkelTx(
      fn(collateral, loan) {
        let loanToken = value.without_lovelace(loan.value)
        expect InlineDatum(datum) = collateral.datum
        expect colDatum: CollateralDatum = datum
        expect InlineDatum(datum) = loan.datum
        expect loanDatum: LoanDatum = datum
        expect Some(loanIn) =
          list.find(
            inputs,
            fn(in) {
              in.output.address.payment_credential == loan.address.payment_credential && value.without_lovelace(
                in.output.value,
              ) == loanToken
            },
          )
        expect InlineDatum(datum) = loanIn.output.datum
        expect lin: LoanDatum = datum
        expect Some(colIn) =
          list.find(
            inputs,
            fn(in) {
              in.output.address.payment_credential == collateral.address.payment_credential && value.without_lovelace(
                in.output.value,
              ) == loanToken
            },
          )
        expect InlineDatum(datum) = colIn.output.datum
        expect cin: CollateralDatum = datum

        let adaOut =
          ( value.lovelace_of(collateral.value) + colDatum.yield ) / 1000000
        let exchangeAdjustment = loanDatum.amount * 1000
        let expectedCollateral = exchangeAdjustment / exchangeRate
        let minCollateralValue = expectedCollateral * 2
        let expectedOracle = value.from_asset(p, loanDatum.oracle, 1)

        adaOut >= minCollateralValue && value.without_lovelace(oracleOut.value) == expectedOracle && loanDatum.amount == lin.amount && cin.yield == colDatum.yield
      },
      r.a,
      outputs,
    )
  }
}

//                 //
// Validator Tests //
//                 //

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
      ..placeholder(),
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [colIn1, loanIn1, oracleIn, userIn1],
      outputs: [colOut1, loanOut1, oracleOut],
      withdrawals: withdraw0,
    }

  let ctx1 = tx.wCtx(t.merkelBalance, tx)

  balance(t.oracleMintHash, t.configMintHash, bRedeemer, ctx1)?
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
      ..placeholder(),
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [colIn1, loanIn1, oracleIn, userIn1],
      outputs: [colOut1, loanOut1, oracleOut],
      withdrawals: withdraw0,
    }

  let ctx1 = tx.wCtx(t.merkelBalance, tx)

  trace @"VULNERABILITY"
  trace @"Vou can change the collateralDatum Amount"

  balance(t.oracleMintHash, t.configMintHash, bRedeemer, ctx1)?
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
      ..placeholder(),
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [colIn1, loanIn1, oracleIn, userIn1],
      outputs: [colOut1, loanOut1, oracleOut],
      withdrawals: withdraw0,
    }

  let ctx1 = tx.wCtx(t.merkelBalance, tx)

  balance(t.oracleMintHash, t.configMintHash, bRedeemer, ctx1)?
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
      ..placeholder(),
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [colIn1, loanIn1, oracleIn, userIn1],
      outputs: [colOut1, loanOut1, oracleOut],
      withdrawals: withdraw0,
    }

  let ctx1 = tx.wCtx(t.merkelBalance, tx)

  balance(t.oracleMintHash, t.configMintHash, bRedeemer, ctx1)?
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

  let vulnToken = value.from_asset(t.loanMintHash, #"deaf", 1)

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
      value.merge(value.from_lovelace(2000000), vulnToken),
      tx.loanOutDatum(outLoanAmount),
    )

  let colOut1 =
    t.test_output(
      t.test_script_address(t.mCol),
      value.merge(value.from_lovelace(outCollateralValue), vulnToken),
      tx.collateralDatumOut(outCollateralAmount, 0),
    )

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [colIn1, loanIn1, oracleIn, userIn1],
      outputs: [colOut1, loanOut1, oracleOut],
      withdrawals: withdraw0,
    }

  let ctx1 = tx.wCtx(t.merkelBalance, tx)

  balance(t.oracleMintHash, t.configMintHash, bRedeemer, ctx1)?
}

test balance_oracleSwap() fail {
  let vulnToken = value.from_asset(t.oracleMintHash, #"1234", 1)

  let vulnOracleValue = value.merge(value.from_lovelace(2000000), vulnToken)
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
      ..placeholder(),
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [colIn1, loanIn1, oracleIn, userIn1],
      outputs: [colOut1, loanOut1, oracleOut],
      withdrawals: withdraw0,
    }

  let ctx1 = tx.wCtx(t.merkelBalance, tx)

  balance(t.oracleMintHash, t.configMintHash, bRedeemer, ctx1)?
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
      ..placeholder(),
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [colIn1, loanIn1, oracleIn, userIn1],
      outputs: [colOut1, loanOut1, oracleOut],
      withdrawals: withdraw0,
    }

  let ctx1 = tx.wCtx(t.merkelBalance, tx)

  balance(t.oracleMintHash, t.configMintHash, bRedeemer, ctx1)?
}
