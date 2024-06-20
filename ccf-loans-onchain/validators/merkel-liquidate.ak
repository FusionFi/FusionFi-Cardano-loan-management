use aiken/dict
use aiken/list
use aiken/transaction.{
  InlineDatum, Input, NoDatum, Output, ScriptContext, Transaction, WithdrawFrom,
  placeholder,
}
use aiken/transaction/credential.{Inline, ScriptCredential}
use aiken/transaction/value.{PolicyId}
use ccfl/helpers.{merkelTx, withdraw4}
use ccfl/types.{
  CollateralDatum, LoanDatum, MerkelConfigDatum, OracleDatum, ScriptHash,
  WithdrawRedeemer,
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
      purpose: WithdrawFrom(stake_credential),
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
    expect cDatum: MerkelConfigDatum = datum
    merkelTx(
      fn(loan, collateral) {
        // expect Some(loanToken) =
        //   list.head(value.flatten(value.without_lovelace(loan.value)))
        // expect InlineDatum(datum) = loan.datum
        // expect loanDatum: LoanDatum = datum
        // expect InlineDatum(datum) = collateral.datum
        // expect colDatum: CollateralDatum = datum
        // let expectedOracle = value.from_asset(p, loanDatum.oracle, 1)
        // expect Some(loanIn) =
        //   list.find(
        //     inputs,
        //     fn(in) {
        //       in.output.address.payment_credential == loan.address.payment_credential && value.flatten(
        //         value.without_lovelace(in.output.value),
        //       ) == [loanToken]
        //     },
        //   )
        // expect InlineDatum(datum) = loanIn.output.datum
        // expect lin: LoanDatum = datum
        // expect Some(colIn) =
        //   list.find(
        //     inputs,
        //     fn(in) {
        //       in.output.address.payment_credential == loan.address.payment_credential && value.flatten(
        //         value.without_lovelace(in.output.value),
        //       ) == [loanToken]
        //     },
        //   )
        // expect InlineDatum(datum) = colIn.output.datum
        // expect cin: CollateralDatum = datum
        // let adaOut = value.lovelace_of(collateral.value) / 1000000
        // let minCollateralValue = loanDatum.amount * exchangeRate * ( 85 / 100 )

        // loanDatum.term == lin.term && adaOut >= minCollateralValue && colDatum.amount == loanDatum.amount && value.flatten(
        //   value.without_lovelace(loan.value),
        // ) == value.flatten(value.without_lovelace(collateral.value)) && value.without_lovelace(
        //   oracleOut.value,
        // ) == expectedOracle
        True
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
  let inRatio = 2
  let outRatio = 2

  let inLoanAmount = 1000
  let inCollateralAmount = 1000
  let inCollateralValue = 2000

  let outLoanAmount = 0
  let outCollateralAmount = 0
  let outCollateralValue = 2

  let test_owner = #"face"

  // withdrawl
  let withdraw0 = tx.withdrawal(t.merkelLiquidate)

  let loanIn1 = tx.mLoanInput(1, inLoanAmount)
  let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue)

  let userIn1 = tx.userInput(2024)

  let configIn = tx.configInput()
  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let loanOut1 = tx.mLoanOutput(outLoanAmount)
  let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue)

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [loanIn1, oracleIn, userIn1, colIn1],
      outputs: [loanOut1, oracleOut, colOut1],
      withdrawals: withdraw0,
    }

  let redeemerList =
    [(0, 2)]

  let ctx1 = tx.wCtx(t.merkelLiquidate, tx)

  liquidate(t.oracleMintHash, t.configMintHash, redeemerList, ctx1)?
}

test separate_liquidate_single() {
  let inRatio = 2
  let outRatio = 2

  let inLoanAmount = 1000
  let inCollateralAmount = 1000
  let inCollateralValue = 2000

  let outLoanAmount = 0
  let outCollateralAmount = 0
  let outCollateralValue = 2

  let test_owner = #"face"

  let loanIn1 = tx.loanInput(1, inLoanAmount)
  let colIn1 = tx.collateralInput(1, inCollateralAmount, inCollateralValue)

  let userIn1 = tx.userInput(2024)

  let configIn = tx.configInput()
  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let loanOut1 = tx.loanOutput(outLoanAmount)
  let colOut1 = tx.collateralOutput(outCollateralAmount, outCollateralValue)

  let withdraw0 =
    dict.from_ascending_list(
      [
        (t.create_stake_credential(t.merkelLoanLiquidate), 0),
        (t.create_stake_credential(t.merkelCollateralLiquidate), 0),
      ],
      t.stakeCompare,
    )

  let loanRedeemer =
    [(0, 0)]

  let colRedeemer =
    [(3, 2)]

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [loanIn1, oracleIn, userIn1, colIn1],
      outputs: [loanOut1, oracleOut, colOut1],
      withdrawals: withdraw0,
    }

  let ctx1 = tx.wCtx(t.merkelLoanLiquidate, tx)

  let ctx2 = tx.wCtx(t.merkelCollateralLiquidate, tx)

  colLiquidate(
    t.merkelCollateralSpend,
    t.loanMintHash,
    t.oracleMintHash,
    t.configMintHash,
    colRedeemer,
    ctx2,
  )? && loanLiquidate(
    t.merkelLoanSpend,
    t.loanMintHash,
    t.oracleMintHash,
    t.configMintHash,
    loanRedeemer,
    ctx1,
  )?
}

test merkel_liquidate_multi() {
  let inRatio = 2
  let outRatio = 2

  let inLoanAmount = 1000
  let inCollateralAmount = 1000
  let inCollateralValue = 2000

  let outLoanAmount = 0
  let outCollateralAmount = 0
  let outCollateralValue = 2

  let test_owner = #"face"

  // withdrawl
  let withdraw0 = tx.withdrawal(t.merkelLiquidate)

  let loanIn1 = tx.mLoanInput(1, inLoanAmount)
  let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue)

  let loanIn2 = tx.mLoanInput(2, inLoanAmount)
  let colIn2 = tx.mCollateralInput(2, inCollateralAmount, inCollateralValue)

  let loanIn3 = tx.mLoanInput(3, inLoanAmount)
  let colIn3 = tx.mCollateralInput(3, inCollateralAmount, inCollateralValue)

  let userIn1 = tx.userInput(2024)

  let configIn = tx.configInput()
  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let loanOut1 = tx.mLoanOutput(outLoanAmount)
  let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue)

  let loanOut2 = tx.mLoanOutput(outLoanAmount)
  let colOut2 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue)

  let loanOut3 = tx.mLoanOutput(outLoanAmount)
  let colOut3 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue)

  let redeemerList =
    [(0, 4), (1, 5), (2, 6)]

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [
        loanIn1,
        loanIn2,
        loanIn3,
        oracleIn,
        userIn1,
        colIn1,
        colIn2,
        colIn3,
      ],
      outputs: [
        loanOut1,
        loanOut2,
        loanOut3,
        oracleOut,
        colOut1,
        colOut2,
        colOut3,
      ],
      withdrawals: withdraw0,
    }

  let ctx5 =
    ScriptContext { purpose: t.withPurpose(t.merkelLiquidate), transaction: tx }

  liquidate(t.oracleMintHash, t.configMintHash, redeemerList, ctx5)?
}

test separate_liquidate_multi() {
  let inRatio = 2
  let outRatio = 2

  let inLoanAmount = 1000
  let inCollateralAmount = 1000
  let inCollateralValue = 2000

  let outLoanAmount = 0
  let outCollateralAmount = 0
  let outCollateralValue = 2

  let test_owner = #"face"

  let configDatum = tx.configDatumIn()

  let loanIn1 = tx.loanInput(1, inLoanAmount)
  let loanIn2 = tx.loanInput(2, inLoanAmount)
  let loanIn3 = tx.loanInput(3, inLoanAmount)

  let colIn1 = tx.collateralInput(1, inCollateralAmount, inCollateralValue)
  let colIn2 = tx.collateralInput(2, inCollateralAmount, inCollateralValue)
  let colIn3 = tx.collateralInput(3, inCollateralAmount, inCollateralValue)

  let userIn1 = tx.userInput(2024)

  let configIn = tx.configInput()

  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let loanOut1 = tx.loanOutput(outLoanAmount)
  let loanOut2 = tx.loanOutput(outLoanAmount)
  let loanOut3 = tx.loanOutput(outLoanAmount)

  let colOut1 = tx.collateralOutput(outCollateralAmount, outCollateralValue)
  let colOut2 = tx.collateralOutput(outCollateralAmount, outCollateralValue)
  let colOut3 = tx.collateralOutput(outCollateralAmount, outCollateralValue)

  let withdraw0 =
    dict.from_ascending_list(
      [
        (t.create_stake_credential(t.merkelLoanLiquidate), 0),
        (t.create_stake_credential(t.merkelCollateralLiquidate), 0),
      ],
      t.stakeCompare,
    )

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [
        loanIn1,
        loanIn2,
        loanIn3,
        oracleIn,
        userIn1,
        colIn1,
        colIn2,
        colIn3,
      ],
      outputs: [
        loanOut1,
        loanOut2,
        loanOut3,
        oracleOut,
        colOut1,
        colOut2,
        colOut3,
      ],
      withdrawals: withdraw0,
    }

  let loanRedeemer =
    [(0, 0), (1, 1), (2, 2)]

  let colRedeemer =
    [(5, 4), (6, 5), (7, 6)]

  let ctx1 = tx.wCtx(t.merkelLoanLiquidate, tx)

  let ctx2 = tx.wCtx(t.merkelCollateralLiquidate, tx)

  colLiquidate(
    t.merkelCollateralSpend,
    t.loanMintHash,
    t.oracleMintHash,
    t.configMintHash,
    colRedeemer,
    ctx2,
  )? && loanLiquidate(
    t.merkelLoanSpend,
    t.loanMintHash,
    t.oracleMintHash,
    t.configMintHash,
    loanRedeemer,
    ctx1,
  )?
}

test loan_datum_fail() fail {
  let inRatio = 2
  let outRatio = 2

  let inLoanAmount = 1000
  let inCollateralAmount = 1000
  let inCollateralValue = 2000

  let outLoanAmount = 1000
  let outCollateralAmount = 0
  let outCollateralValue = 2

  let test_owner = #"face"

  // withdrawl
  let withdraw0 = tx.withdrawal(t.merkelLiquidate)

  let loanIn1 = tx.mLoanInput(1, inLoanAmount)
  let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue)

  let userIn1 = tx.userInput(2024)

  let configIn = tx.configInput()
  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let loanOut1 = tx.mLoanOutput(outLoanAmount)
  let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue)

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [loanIn1, oracleIn, userIn1, colIn1],
      outputs: [loanOut1, oracleOut, colOut1],
      withdrawals: withdraw0,
    }

  let redeemerList =
    [(0, 2)]

  let ctx1 = tx.wCtx(t.merkelLiquidate, tx)

  liquidate(t.oracleMintHash, t.configMintHash, redeemerList, ctx1)?
}

test loan_token_fail() fail {
  let inRatio = 2
  let outRatio = 2
  let fakeToken = value.from_asset(t.loanMintHash, #"deaf", 1)

  let inLoanAmount = 1000
  let inCollateralAmount = 1000
  let inCollateralValue = 2000

  let outLoanAmount = 0
  let outCollateralAmount = 0
  let outCollateralValue = 2

  let test_owner = #"face"

  // withdrawl
  let withdraw0 = tx.withdrawal(t.merkelLiquidate)

  let loanIn1 = tx.mLoanInput(1, inLoanAmount)
  let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue)

  let userIn1 = tx.userInput(2024)

  let configIn = tx.configInput()
  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let loanOut1 =
    t.test_output(
      t.test_script_address(t.mLoan),
      value.merge(t.makeAdaValue(2), fakeToken),
      tx.loanOutDatum(1000),
    )
  let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue)

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [loanIn1, oracleIn, userIn1, colIn1],
      outputs: [loanOut1, oracleOut, colOut1],
      withdrawals: withdraw0,
    }

  let redeemerList =
    [(0, 2)]

  let ctx1 = tx.wCtx(t.merkelLiquidate, tx)

  liquidate(t.oracleMintHash, t.configMintHash, redeemerList, ctx1)?
}

test collateral_value_fail() {
  let inRatio = 2
  let outRatio = 2

  let inLoanAmount = 1000
  let inCollateralAmount = 1000
  let inCollateralValue = 2000

  let outLoanAmount = 0
  let outCollateralAmount = 0
  let outCollateralValue = 2000

  let test_owner = #"face"

  // withdrawl
  let withdraw0 = tx.withdrawal(t.merkelLiquidate)

  let loanIn1 = tx.mLoanInput(1, inLoanAmount)
  let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue)

  let userIn1 = tx.userInput(2024)

  let configIn = tx.configInput()
  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let loanOut1 = tx.mLoanOutput(outLoanAmount)
  let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue)

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [loanIn1, oracleIn, userIn1, colIn1],
      outputs: [loanOut1, oracleOut, colOut1],
      withdrawals: withdraw0,
    }

  let redeemerList =
    [(0, 2)]

  let ctx1 = tx.wCtx(t.merkelLiquidate, tx)

  liquidate(t.oracleMintHash, t.configMintHash, redeemerList, ctx1)?
}

test collateral_token_fail() fail {
  let inRatio = 2
  let outRatio = 2
  let fakeToken = value.from_asset(t.loanMintHash, #"deaf", 1)

  let inLoanAmount = 1000
  let inCollateralAmount = 1000
  let inCollateralValue = 2000

  let outLoanAmount = 0
  let outCollateralAmount = 0
  let outCollateralValue = 2

  let test_owner = #"face"

  // withdrawl
  let withdraw0 = tx.withdrawal(t.merkelLiquidate)

  let loanIn1 = tx.mLoanInput(1, inLoanAmount)
  let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue)

  let userIn1 = tx.userInput(2024)

  let configIn = tx.configInput()
  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let loanOut1 = tx.mLoanOutput(outLoanAmount)
  let colOut1 =
    t.test_output(
      t.test_script_address(t.merkelCollateralSpend),
      value.merge(t.makeAdaValue(2), fakeToken),
      tx.collateralDatumOut(0),
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

  let redeemerList =
    [(0, 2)]

  let ctx1 = tx.wCtx(t.merkelLiquidate, tx)

  liquidate(t.oracleMintHash, t.configMintHash, redeemerList, ctx1)?
}

test oracle_datum_fail() fail {
  let inRatio = 2
  let outRatio = 2

  let inLoanAmount = 1000
  let inCollateralAmount = 1000
  let inCollateralValue = 2000

  let outLoanAmount = 0
  let outCollateralAmount = 0
  let outCollateralValue = 2

  let test_owner = #"face"

  // withdrawl
  let withdraw0 = tx.withdrawal(t.merkelLiquidate)

  let loanIn1 = tx.mLoanInput(1, inLoanAmount)
  let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue)

  let userIn1 = tx.userInput(2024)

  let configIn = tx.configInput()
  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut =
    t.test_output(
      t.test_script_address(t.merkelLoanSpend),
      t.loanTokenValue(),
      tx.loanOutDatum(100),
    )

  let loanOut1 = tx.mLoanOutput(outLoanAmount)
  let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue)

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [loanIn1, oracleIn, userIn1, colIn1],
      outputs: [loanOut1, oracleOut, colOut1],
      withdrawals: withdraw0,
    }

  let redeemerList =
    [(0, 2)]

  let ctx1 = tx.wCtx(t.merkelLiquidate, tx)

  liquidate(t.oracleMintHash, t.configMintHash, redeemerList, ctx1)?
}

test oracle_token_fail() fail {
  let inRatio = 2
  let outRatio = 2

  let inLoanAmount = 1000
  let inCollateralAmount = 1000
  let inCollateralValue = 2000

  let outLoanAmount = 0
  let outCollateralAmount = 0
  let outCollateralValue = 2

  let test_owner = #"face"

  // withdrawl
  let withdraw0 = tx.withdrawal(t.merkelLiquidate)

  let loanIn1 = tx.mLoanInput(1, inLoanAmount)
  let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue)

  let userIn1 = tx.userInput(2024)

  let configIn = tx.configInput()
  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      t.loanValue(),
      tx.oracleOutDatum(inRatio),
    )

  let loanOut1 = tx.mLoanOutput(outLoanAmount)
  let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue)

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [loanIn1, oracleIn, userIn1, colIn1],
      outputs: [loanOut1, oracleOut, colOut1],
      withdrawals: withdraw0,
    }

  let redeemerList =
    [(0, 2)]

  let ctx1 = tx.wCtx(t.merkelLiquidate, tx)

  liquidate(t.oracleMintHash, t.configMintHash, redeemerList, ctx1)?
}

test config_datum_fail() fail {
  let inRatio = 2
  let outRatio = 2

  let inLoanAmount = 1000
  let inCollateralAmount = 1000
  let inCollateralValue = 2000

  let outLoanAmount = 0
  let outCollateralAmount = 0
  let outCollateralValue = 2

  let test_owner = #"face"

  // withdrawl
  let withdraw0 = tx.withdrawal(t.merkelLiquidate)

  let loanIn1 = tx.mLoanInput(1, inLoanAmount)
  let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue)

  let userIn1 = tx.userInput(2024)

  let configIn = tx.oracleInput(inRatio)
  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let loanOut1 = tx.mLoanOutput(outLoanAmount)
  let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue)

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [loanIn1, oracleIn, userIn1, colIn1],
      outputs: [loanOut1, oracleOut, colOut1],
      withdrawals: withdraw0,
    }

  let redeemerList =
    [(0, 2)]

  let ctx1 = tx.wCtx(t.merkelLiquidate, tx)

  liquidate(t.oracleMintHash, t.configMintHash, redeemerList, ctx1)?
}

test config_token_fail() fail {
  let inRatio = 2
  let outRatio = 2

  let inLoanAmount = 1000
  let inCollateralAmount = 1000
  let inCollateralValue = 2000

  let outLoanAmount = 0
  let outCollateralAmount = 0
  let outCollateralValue = 2

  let test_owner = #"face"

  // withdrawl
  let withdraw0 = tx.withdrawal(t.merkelLiquidate)

  let loanIn1 = tx.mLoanInput(1, inLoanAmount)
  let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue)

  let userIn1 = tx.userInput(2024)

  let configIn = tx.oracleInput(inRatio)
  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let loanOut1 = tx.mLoanOutput(outLoanAmount)
  let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue)

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [loanIn1, oracleIn, userIn1, colIn1],
      outputs: [loanOut1, oracleOut, colOut1],
      withdrawals: withdraw0,
    }

  let redeemerList =
    [(0, 2)]

  let ctx1 = tx.wCtx(t.merkelLiquidate, tx)

  liquidate(t.oracleMintHash, t.configMintHash, redeemerList, ctx1)?
}

// Merkel Loan && Collateral for comparison tests //

validator(loanVal: ScriptHash, lp: PolicyId, op: PolicyId, cp: PolicyId) {
  fn loanLiquidate(r: List<(Int, Int)>, c: ScriptContext) {
    expect ScriptContext { transaction, purpose: WithdrawFrom(stake_cred) } = c

    let Transaction { outputs, reference_inputs, .. } = transaction

    expect Inline(ScriptCredential(_own_validator)) = stake_cred

    expect Some(oracleOut) =
      list.find(
        outputs,
        fn(output) { list.has(value.policies(output.value), op) },
      )

    expect InlineDatum(datum) = oracleOut.datum
    expect rDatum: OracleDatum = datum

    let exchangeRate = rDatum.usdAda

    expect Some(configIn) =
      list.find(
        reference_inputs,
        fn(input) { list.has(value.policies(input.output.value), cp) },
      )

    expect InlineDatum(datum) = configIn.output.datum
    expect cDatum: MerkelConfigDatum = datum

    withdraw4(
      fn(input, output) {
        // input here is already an input.output
        expect InlineDatum(datum) = input.datum
        expect d: LoanDatum = datum

        expect Some(loanToken) =
          list.head(value.flatten(value.without_lovelace(input.value)))

        expect Some(colOut) =
          list.find(
            outputs,
            fn(output) {
              expect Some(colToken) =
                list.head(value.flatten(value.without_lovelace(output.value)))

              output.address.payment_credential == ScriptCredential(
                cDatum.colVal,
              ) && loanToken == colToken
            },
          )

        expect InlineDatum(datum) = colOut.datum
        expect colDatum: CollateralDatum = datum

        let adaOut = value.lovelace_of(colOut.value) / 1000000

        expect list.has(value.policies(output.value), lp)

        expect InlineDatum(datum) = output.datum
        expect datum: LoanDatum = datum

        let minCollateralValue = datum.amount * exchangeRate * ( 85 / 100 )

        input.address.payment_credential == output.address.payment_credential && datum.interest == d.interest && datum.term == d.term && adaOut >= minCollateralValue
      },
      loanVal,
      r,
      transaction,
    )
  }
}

validator(colVal: ScriptHash, lp: PolicyId, op: PolicyId, cp: PolicyId) {
  fn colLiquidate(r: List<(Int, Int)>, c: ScriptContext) {
    expect ScriptContext { transaction, purpose: WithdrawFrom(stake_cred) } = c

    let Transaction { outputs, reference_inputs, .. } = transaction

    expect Inline(ScriptCredential(_own_validator)) = stake_cred

    expect Some(oracleOut) =
      list.find(
        outputs,
        fn(output) { list.has(value.policies(output.value), op) },
      )

    expect InlineDatum(datum) = oracleOut.datum
    expect rDatum: OracleDatum = datum

    let exchangeRate = rDatum.usdAda

    expect Some(configIn) =
      list.find(
        reference_inputs,
        fn(input) { list.has(value.policies(input.output.value), cp) },
      )

    expect InlineDatum(datum) = configIn.output.datum
    expect cDatum: MerkelConfigDatum = datum

    withdraw4(
      fn(input, output) {
        expect Some(collateralToken) =
          list.head(value.flatten(value.without_lovelace(input.value)))

        expect Some(loanOut) =
          list.find(
            outputs,
            fn(output) {
              expect Some(loanToken) =
                list.head(value.flatten(value.without_lovelace(output.value)))

              output.address.payment_credential == ScriptCredential(
                cDatum.loanVal,
              ) && loanToken == collateralToken
            },
          )

        expect InlineDatum(datum) = loanOut.datum
        expect lDatum: LoanDatum = datum

        let adaOut = value.lovelace_of(output.value) / 1000000

        let minCollateralValue = lDatum.amount * exchangeRate * ( 85 / 100 )

        expect InlineDatum(datum) = output.datum
        expect outDatum: CollateralDatum = datum

        input.address.payment_credential == output.address.payment_credential && adaOut >= minCollateralValue && outDatum.amount == lDatum.amount && list.has(
          value.flatten(output.value),
          collateralToken,
        )
      },
      colVal,
      r,
      transaction,
    )
  }
}
