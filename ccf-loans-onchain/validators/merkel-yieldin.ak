use aiken/list
use aiken/transaction.{
  InlineDatum, Input, NoDatum, Output, ScriptContext, Transaction, WithdrawFrom,
  placeholder,
}
use aiken/transaction/credential.{Address, ScriptCredential}
use aiken/transaction/value.{PolicyId}
use ccfl/helpers.{merkelYield}
use ccfl/types.{CollateralDatum, MerkelConfigDatum, WithdrawRedeemer}
use tests/tools as t
use tests/transactions as tx

// type CYieldDatum {
//   amount: Int,
//   timestamp: Int,
//   yield: Int,
// }

validator(cp: PolicyId) {
  fn yieldDeposit(r: WithdrawRedeemer, c: ScriptContext) {
    expect ScriptContext {
      transaction,
      purpose: WithdrawFrom(_stake_credential),
    } = c

    let Transaction { inputs, outputs, reference_inputs, .. } = transaction

    expect Some(configIn) =
      list.find(
        reference_inputs,
        fn(input) { list.has(value.policies(input.output.value), cp) },
      )

    expect InlineDatum(datum) = configIn.output.datum
    expect cDatum: MerkelConfigDatum = datum

    merkelYield(
      outputs,
      r.a,
      fn(collateral) {
        let loanToken = value.without_lovelace(collateral.value)

        expect InlineDatum(datum) = collateral.datum
        expect outDatum: CollateralDatum = datum
        let outYield = outDatum.yield

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
        expect inDatum: CollateralDatum = datum
        let inYield = inDatum.yield

        expect Some(_yieldOut) =
          list.find(
            outputs,
            fn(out) {
              out.value == value.from_lovelace(outYield - inYield) && out.address.payment_credential == ScriptCredential(
                cDatum.yield,
              )
            },
          )

        outDatum.yield + value.lovelace_of(collateral.value) == inDatum.yield + value.lovelace_of(
          colIn.output.value,
        ) && inDatum.yield < outDatum.yield
      },
    )
  }
}

test yieldIn() {
  let inRatio = 1000
  let outRatio = 1000

  let inCollateralAmount = 2000
  let inCollateralValue = 2000

  let outCollateralAmount = 2000
  let outCollateralValue = 1000
  let outYield = 1000

  let userIn1 = tx.userInput(2024)
  let configIn = tx.configInput()
  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let inDatum =
    CollateralDatum {
      amount: inCollateralAmount,
      timestamp: 1111111111,
      yield: 0,
    }
  let outDatum =
    CollateralDatum {
      amount: outCollateralAmount,
      timestamp: 1724449574,
      yield: outYield,
    }

  let colIn1 =
    t.test_input(
      tx.oref(#"cafe", 1),
      t.test_output(
        t.test_script_address(t.mCol),
        value.merge(value.from_lovelace(inCollateralValue), t.loanTokenValue()),
        InlineDatum(inDatum),
      ),
    )

  let colOut1 =
    t.test_output(
      t.test_script_address(t.mCol),
      value.merge(value.from_lovelace(outCollateralValue), t.loanTokenValue()),
      InlineDatum(outDatum),
    )

  let yieldOut =
    Output {
      address: Address {
        payment_credential: ScriptCredential(#"bebe"),
        stake_credential: None,
      },
      value: value.from_lovelace(outYield),
      datum: NoDatum,
      reference_script: None,
    }

  // withdrawl
  let withdraw0 = tx.withdrawal(t.yieldIn)
  let withdrawRedeemer = tx.withdrawRedeemer([0])

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      inputs: [colIn1, oracleIn, userIn1],
      outputs: [colOut1, yieldOut, oracleOut],
      withdrawals: withdraw0,
    }

  let scriptContext = tx.wCtx(t.yieldIn, tx)

  yieldDeposit(t.configMintHash, withdrawRedeemer, scriptContext)?
}

test yield_colFail() fail {
  let inRatio = 1000
  let outRatio = 1000

  let inCollateralAmount = 2000
  let inCollateralValue = 2000

  let outCollateralAmount = 2000
  let outCollateralValue = 2000
  let outYield = 1000

  let userIn1 = tx.userInput(2024)
  let configIn = tx.configInput()
  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let inDatum =
    CollateralDatum {
      amount: inCollateralAmount,
      timestamp: 1111111111,
      yield: 0,
    }
  let outDatum =
    CollateralDatum {
      amount: outCollateralAmount,
      timestamp: 1724449574,
      yield: outYield,
    }

  let colIn1 =
    t.test_input(
      tx.oref(#"cafe", 1),
      t.test_output(
        t.test_script_address(t.mCol),
        value.merge(value.from_lovelace(inCollateralValue), t.loanTokenValue()),
        InlineDatum(inDatum),
      ),
    )

  let colOut1 =
    t.test_output(
      t.test_script_address(t.mCol),
      value.merge(value.from_lovelace(outCollateralValue), t.loanTokenValue()),
      InlineDatum(outDatum),
    )

  let yieldOut =
    Output {
      address: Address {
        payment_credential: ScriptCredential(#"bebe"),
        stake_credential: None,
      },
      value: value.from_lovelace(outYield),
      datum: NoDatum,
      reference_script: None,
    }

  // withdrawl
  let withdraw0 = tx.withdrawal(t.yieldIn)
  let withdrawRedeemer = tx.withdrawRedeemer([0])

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      inputs: [colIn1, oracleIn, userIn1],
      outputs: [colOut1, yieldOut, oracleOut],
      withdrawals: withdraw0,
    }

  let scriptContext = tx.wCtx(t.yieldIn, tx)

  yieldDeposit(t.configMintHash, withdrawRedeemer, scriptContext)?
}

test yield_multi() {
  let loanValue1 = value.from_asset(t.loanMintHash, "baba", 1)
  let loanValue2 = value.from_asset(t.loanMintHash, "bbbb", 1)
  let loanValue3 = value.from_asset(t.loanMintHash, "bcbc", 1)

  let inRatio = 1000
  let outRatio = 1000

  let inCollateralAmount = 2000
  let inCollateralValue = 2000

  let outCollateralAmount = 2000
  let outCollateralValue = 1000
  let outYield = 1000

  let userIn1 = tx.userInput(2024)
  let configIn = tx.configInput()
  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let inDatum =
    CollateralDatum {
      amount: inCollateralAmount,
      timestamp: 1111111111,
      yield: 0,
    }

  let outDatum =
    CollateralDatum {
      amount: outCollateralAmount,
      timestamp: 1724449574,
      yield: outYield,
    }

  let colIn1 =
    t.test_input(
      tx.oref(#"cafe", 1),
      t.test_output(
        t.test_script_address(t.mCol),
        value.merge(value.from_lovelace(inCollateralValue), loanValue1),
        InlineDatum(inDatum),
      ),
    )

  let colIn2 =
    t.test_input(
      tx.oref(#"cafe", 2),
      t.test_output(
        t.test_script_address(t.mCol),
        value.merge(value.from_lovelace(inCollateralValue), loanValue2),
        InlineDatum(inDatum),
      ),
    )

  let colIn3 =
    t.test_input(
      tx.oref(#"cafe", 3),
      t.test_output(
        t.test_script_address(t.mCol),
        value.merge(value.from_lovelace(inCollateralValue), loanValue3),
        InlineDatum(inDatum),
      ),
    )

  let colOut1 =
    t.test_output(
      t.test_script_address(t.mCol),
      value.merge(value.from_lovelace(outCollateralValue), loanValue1),
      InlineDatum(outDatum),
    )

  let colOut2 =
    t.test_output(
      t.test_script_address(t.mCol),
      value.merge(value.from_lovelace(outCollateralValue), loanValue2),
      InlineDatum(outDatum),
    )

  let colOut3 =
    t.test_output(
      t.test_script_address(t.mCol),
      value.merge(value.from_lovelace(outCollateralValue), loanValue3),
      InlineDatum(outDatum),
    )

  let yieldOut1 =
    Output {
      address: Address {
        payment_credential: ScriptCredential(#"bebe"),
        stake_credential: None,
      },
      value: value.from_lovelace(outYield),
      datum: NoDatum,
      reference_script: None,
    }

  let yieldOut2 =
    Output {
      address: Address {
        payment_credential: ScriptCredential(#"bebe"),
        stake_credential: None,
      },
      value: value.from_lovelace(outYield),
      datum: NoDatum,
      reference_script: None,
    }

  let yieldOut3 =
    Output {
      address: Address {
        payment_credential: ScriptCredential(#"bebe"),
        stake_credential: None,
      },
      value: value.from_lovelace(outYield),
      datum: NoDatum,
      reference_script: None,
    }

  // withdrawl
  let withdraw0 = tx.withdrawal(t.yieldIn)
  let withdrawRedeemer = tx.withdrawRedeemer([0, 2, 4])

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      inputs: [colIn1, colIn2, colIn3, oracleIn, userIn1],
      outputs: [
        colOut1,
        yieldOut1,
        colOut2,
        yieldOut2,
        colOut3,
        yieldOut3,
        oracleOut,
      ],
      withdrawals: withdraw0,
    }

  let scriptContext = tx.wCtx(t.yieldIn, tx)

  yieldDeposit(t.configMintHash, withdrawRedeemer, scriptContext)?
}
