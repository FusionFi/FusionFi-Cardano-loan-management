use aiken/list
use aiken/transaction.{
  InlineDatum, Input, Output, ScriptContext, Transaction, WithdrawFrom,
  placeholder,
}
use aiken/transaction/value.{PolicyId}
use ccfl/helpers.{merkelTx}
use ccfl/types.{
  CollateralDatum, LoanDatum, MerkelConfigDatum, OracleDatum, WithdrawRedeemer,
}
use tests/tools as t
use tests/transactions as tx

//                              //
// Merkel Liquidation Validator //
//                              //

validator(p: PolicyId, cp: PolicyId) {
  fn liquidate(r: WithdrawRedeemer, c: ScriptContext) {
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

        let expectedOracle = value.from_asset(p, lin.oracle, 1)

        let exchangeAdjustment = lin.amount * 1000
        let loanExpected = exchangeAdjustment / exchangeRate

        // let adaOut = value.lovelace_of(collateral.value) / 1000000
        let ratio = loanDatum.amount * 1000 / ( exchangeAdjustment / 100 )

        value.lovelace_of(colIn.output.value) / 1000000 <= loanExpected * 85 / 100 && value.without_lovelace(
          oracleOut.value,
        ) == expectedOracle && value.lovelace_of(collateral.value) >= value.lovelace_of(
          colIn.output.value,
        ) * ratio && colDatum.amount == loanDatum.amount * 2 && cin.yield == colDatum.yield
      },
      r.a,
      outputs,
    )
  }
}

//                 //
// Validator Tests //
//                 //

test merkel_liquidate_single() {
  let inRatio = 200
  let outRatio = 200

  let inLoanAmount = 1000
  let inCollateralAmount = 2000
  let inCollateralValue = 4000

  let outLoanAmount = 0
  let outCollateralAmount = 0
  let outCollateralValue = 2

  let test_owner = #"face"

  // withdrawl
  let withdraw0 = tx.withdrawal(t.merkelLiquidate)

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
      inputs: [loanIn1, oracleIn, userIn1, colIn1],
      outputs: [loanOut1, oracleOut, colOut1],
      withdrawals: withdraw0,
    }

  let redeemerList = tx.withdrawRedeemer([2])

  let ctx1 = tx.wCtx(t.merkelLiquidate, tx)

  liquidate(t.oracleMintHash, t.configMintHash, redeemerList, ctx1)?
}

test liquidate_loanAmtFail() fail {
  let inRatio = 200
  let outRatio = 200

  let inLoanAmount = 1000
  let inCollateralAmount = 2000
  let inCollateralValue = 4000

  let outLoanAmount = 10
  let outCollateralAmount = 0
  let outCollateralValue = 2

  let test_owner = #"face"

  // withdrawl
  let withdraw0 = tx.withdrawal(t.merkelLiquidate)

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
      inputs: [loanIn1, oracleIn, userIn1, colIn1],
      outputs: [loanOut1, oracleOut, colOut1],
      withdrawals: withdraw0,
    }

  let redeemerList = tx.withdrawRedeemer([2])

  let ctx1 = tx.wCtx(t.merkelLiquidate, tx)

  liquidate(t.oracleMintHash, t.configMintHash, redeemerList, ctx1)?
}

test liquidate_colAmtFail() fail {
  let inRatio = 200
  let outRatio = 200

  let inLoanAmount = 1000
  let inCollateralAmount = 2000
  let inCollateralValue = 4000

  let outLoanAmount = 0
  let outCollateralAmount = 10
  let outCollateralValue = 2

  let test_owner = #"face"

  // withdrawl
  let withdraw0 = tx.withdrawal(t.merkelLiquidate)

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
      inputs: [loanIn1, oracleIn, userIn1, colIn1],
      outputs: [loanOut1, oracleOut, colOut1],
      withdrawals: withdraw0,
    }

  let redeemerList = tx.withdrawRedeemer([2])

  let ctx1 = tx.wCtx(t.merkelLiquidate, tx)

  liquidate(t.oracleMintHash, t.configMintHash, redeemerList, ctx1)?
}

test liquidate_tokenSwap() fail {
  let inRatio = 200
  let outRatio = 200

  let inLoanAmount = 1000
  let inCollateralAmount = 2000
  let inCollateralValue = 4000

  let outLoanAmount = 0
  let outCollateralAmount = 0
  let outCollateralValue = 2

  let vulnToken = value.from_asset(t.loanMintHash, #"deaf", 1)

  let test_owner = #"face"

  // withdrawl
  let withdraw0 = tx.withdrawal(t.merkelLiquidate)

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
      inputs: [loanIn1, oracleIn, userIn1, colIn1],
      outputs: [loanOut1, oracleOut, colOut1],
      withdrawals: withdraw0,
    }

  let redeemerList = tx.withdrawRedeemer([2])

  let ctx1 = tx.wCtx(t.merkelLiquidate, tx)

  liquidate(t.oracleMintHash, t.configMintHash, redeemerList, ctx1)?
}

test liquidate_oracleSwap() fail {
  let vulnToken = value.from_asset(t.oracleMintHash, #"1234", 1)

  let vulnOracleValue = value.merge(value.from_lovelace(2000000), vulnToken)

  let inRatio = 200
  let outRatio = 200

  let inLoanAmount = 1000
  let inCollateralAmount = 2000
  let inCollateralValue = 4000

  let outLoanAmount = 0
  let outCollateralAmount = 0
  let outCollateralValue = 2

  let test_owner = #"face"

  // withdrawl
  let withdraw0 = tx.withdrawal(t.merkelLiquidate)

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
      inputs: [loanIn1, oracleIn, userIn1, colIn1],
      outputs: [loanOut1, oracleOut, colOut1],
      withdrawals: withdraw0,
    }

  let redeemerList = tx.withdrawRedeemer([2])

  let ctx1 = tx.wCtx(t.merkelLiquidate, tx)

  liquidate(t.oracleMintHash, t.configMintHash, redeemerList, ctx1)?
}
