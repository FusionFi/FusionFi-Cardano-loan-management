use aiken/dict
use aiken/list
use aiken/transaction.{
  InlineDatum, NoDatum, Output, ScriptContext, Transaction, WithdrawFrom,
  placeholder,
}
use aiken/transaction/credential.{Inline, ScriptCredential}
use aiken/transaction/value.{PolicyId}
use ccfl/helpers.{merkelBurn}
use ccfl/types.{CollateralDatum, LoanDatum, WithdrawRedeemer}
use tests/tools as t
use tests/transactions as tx

//                        //
// Merkel Close Validator //
//                        //

validator(lp: PolicyId, op: PolicyId) {
  fn close(r: WithdrawRedeemer, c: ScriptContext) {
    expect ScriptContext {
      transaction,
      purpose: WithdrawFrom(stake_credential),
    } = c

    let Transaction { inputs, outputs, mint, .. } = transaction

    expect Inline(ScriptCredential(_own_validator)) = stake_credential

    expect Some(_oracleOut) =
      list.find(
        outputs,
        fn(output) { list.has(value.policies(output.value), op) },
      )

    merkelBurn(
      fn(loan, collateral) {
        expect InlineDatum(datum) = loan.datum
        expect ld: LoanDatum = datum
        expect InlineDatum(datum) = collateral.datum
        expect cd: CollateralDatum = datum
        let loanTokenValue = value.without_lovelace(loan.value)
        let colTokenValue = value.without_lovelace(collateral.value)
        expect [Pair(loanTn, 1)] =
          loanTokenValue
            |> value.tokens(lp)
            |> dict.to_pairs()
        expect Some(burnVal) =
          value.zero()
            |> value.add(lp, loanTn, -2)
            |> value.flatten()
            |> list.head()
        let burns =
          mint
            |> value.from_minted_value()
            |> value.flatten()
        expect list.has(burns, burnVal)
        ld.amount == 0 && cd.amount == 0 && loanTokenValue == colTokenValue && cd.yield == 0
      },
      r.a,
      inputs,
    )
  }
}

//                 //
// Validator Tests //
//                 //

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
      ..placeholder(),
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [loanIn1, oracleIn, userIn1, colIn1],
      outputs: [oracleOut],
      mint: value.to_minted_value(t.loanBurnValue()),
      withdrawals: withdraw0,
    }

  let ctx5 = tx.wCtx(t.merkelClose, tx)

  close(t.loanMintHash, t.oracleMintHash, redeemerList, ctx5)?
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
      ..placeholder(),
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [loanIn1, oracleIn, userIn1, colIn1],
      outputs: [oracleOut],
      mint: value.to_minted_value(t.loanBurnValue()),
      withdrawals: withdraw0,
    }

  let ctx5 = tx.wCtx(t.merkelClose, tx)

  close(t.loanMintHash, t.oracleMintHash, redeemerList, ctx5)?
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
      ..placeholder(),
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [loanIn1, oracleIn, userIn1, colIn1],
      outputs: [oracleOut],
      mint: value.to_minted_value(t.loanBurnValue()),
      withdrawals: withdraw0,
    }

  let ctx5 = tx.wCtx(t.merkelClose, tx)

  close(t.loanMintHash, t.oracleMintHash, redeemerList, ctx5)?
}

test close_tokenSwap() fail {
  let vulnToken = value.from_asset(t.loanMintHash, #"dede", -2)

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
      value.merge(t.loanTokenValue(), t.loanTokenValue()),
      NoDatum,
    )

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [loanIn1, oracleIn, userIn1, colIn1],
      outputs: [oracleOut, vulnOut],
      mint: value.to_minted_value(vulnToken),
      withdrawals: withdraw0,
    }

  let ctx5 = tx.wCtx(t.merkelClose, tx)

  close(t.loanMintHash, t.oracleMintHash, redeemerList, ctx5)?
}

test close_oracleSwap() {
  let vulnToken = value.from_asset(t.oracleMintHash, #"1234", 1)

  let vulnOracleValue = value.merge(value.from_lovelace(2000000), vulnToken)

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
      ..placeholder(),
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [loanIn1, oracleIn, userIn1, colIn1],
      outputs: [oracleOut],
      mint: value.to_minted_value(t.loanBurnValue()),
      withdrawals: withdraw0,
    }

  let ctx5 = tx.wCtx(t.merkelClose, tx)

  trace @"VULNERABILITY"
  trace @"Allows to swap oracle token output"
  close(t.loanMintHash, t.oracleMintHash, redeemerList, ctx5)?
}
