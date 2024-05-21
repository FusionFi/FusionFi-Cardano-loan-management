use aiken/dict
use aiken/list
use aiken/transaction.{
  InlineDatum, NoDatum, Output, ScriptContext, Transaction, WithdrawFrom,
  placeholder,
}
use aiken/transaction/credential.{Inline, ScriptCredential}
use aiken/transaction/value.{PolicyId}
use ccfl/helpers.{merkelBurn, withBurn}
use ccfl/types.{CollateralDatum, LoanDatum, ScriptHash}
use tests/tools as t
use tests/transactions as tx

//                              //
// merkel Liquidation validator //
//                              //

validator(lp: PolicyId, op: PolicyId) {
  fn close(r: List<(Int, Int)>, c: ScriptContext) {
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

        expect [(loanTn, 1)] =
          loanTokenValue
            |> value.tokens(lp)
            |> dict.to_list()

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

        ld.amount == 0 && cd.amount == 0 && loanTokenValue == colTokenValue
      },
      r,
      inputs,
    )
  }
}

//                 //
// Validator Tests //
//                 //

validator(loanVal: ScriptHash, lp: PolicyId, op: PolicyId) {
  fn loanClose(r: List<Int>, c: ScriptContext) {
    expect ScriptContext { transaction, purpose: WithdrawFrom(stake_cred) } = c

    let Transaction { outputs, mint, .. } = transaction

    expect Inline(ScriptCredential(_own_validator)) = stake_cred

    expect Some(_oracleOut) =
      list.find(
        outputs,
        fn(output) { list.has(value.policies(output.value), op) },
      )

    withBurn(
      fn(input) {
        expect InlineDatum(datum) = input.datum
        expect d: LoanDatum = datum

        let loanTokenVal = value.without_lovelace(input.value)
        expect [(loanTn, 1)] =
          loanTokenVal
            |> value.tokens(lp)
            |> dict.to_list()

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
        d.amount == 0
      },
      loanVal,
      r,
      transaction,
    )
  }
}

validator(colVal: ScriptHash, lp: PolicyId, op: PolicyId) {
  fn collateralClose(r: List<Int>, c: ScriptContext) {
    expect ScriptContext { transaction, purpose: WithdrawFrom(stake_cred) } = c

    let Transaction { outputs, mint, .. } = transaction

    expect Inline(ScriptCredential(_own_validator)) = stake_cred

    expect Some(_oracleOut) =
      list.find(
        outputs,
        fn(output) { list.has(value.policies(output.value), op) },
      )

    withBurn(
      fn(input) {
        expect InlineDatum(datum) = input.datum
        expect d: CollateralDatum = datum

        let loanTokenVal = value.without_lovelace(input.value)
        expect [(loanTn, 1)] =
          loanTokenVal
            |> value.tokens(lp)
            |> dict.to_list()

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
        d.amount == 0
      },
      colVal,
      r,
      transaction,
    )
  }
}

test merkel_close_single() {
  let test_owner = #"face"

  // let test_user = #"cafe"
  let oref1 = t.test_oref(#"face", 1)
  let cref1 = t.test_oref(#"cafe", 2)
  let rref = t.test_oref(#"dead", 6)
  let uref1 = t.test_oref(#"beef", 4)
  let href1 = t.test_oref(#"feed", 3)

  // let loanAction = tx.merkelLoanAction(2)
  let configDatum =
    tx.mConfigDatum(
      t.merkelLoanSpend,
      t.collateralValHash,
      t.rewardsMintHash,
      t.oracleValHash,
      [t.merkelLoanBalance, t.merkelLoanLiquidate, t.merkelLoanClose],
      [
        t.merkelCollateralBalance,
        t.merkelBalance,
        t.merkelLiquidate,
        t.merkelClose,
      ],
    )
  let configInDatum = InlineDatum(configDatum)

  let loanDatum1 = tx.loanDatum(0, 15, 1000, 0, 1111111114)
  let loanInDatum = InlineDatum(loanDatum1)
  let loanInValue = t.loanTokenValue()

  let loanDatum2 = tx.loanDatum(0, 15, 1000, 0, 1111111115)

  let collateralDatum1 = tx.collateralDatum(0, 12)
  let colInDatum = InlineDatum(collateralDatum1)
  let colInValue = t.loanTokenValue()

  let collateralDatum2 = tx.collateralDatum(1000, 12)

  let oracleInDatum = tx.oracleDatum(2, 11111112, 15, 2)
  let oracleOutDatum = tx.oracleDatum(2, 11111114, 15, 2)

  let oInDatum = InlineDatum(oracleInDatum)
  let oOutDatum = InlineDatum(oracleOutDatum)

  let noDatum = NoDatum

  let withdraw0 =
    dict.from_ascending_list(
      [(t.create_stake_credential(t.merkelClose), 0)],
      t.stakeCompare,
    )

  let redeemerList =
    [(0, 3)]

  let loanIn1 =
    t.test_input(
      oref1,
      t.test_output(t.test_script_address(t.mLoan), loanInValue, loanInDatum),
    )

  let colIn1 =
    t.test_input(
      href1,
      t.test_output(t.test_script_address(t.mCol), colInValue, colInDatum),
    )

  let userIn1 =
    t.test_input(
      uref1,
      t.test_output(t.test_address(#"cafe"), t.makeAdaValue(2010), noDatum),
    )

  let configIn =
    t.test_input(
      cref1,
      t.test_output(
        t.test_script_address(t.configValHash),
        t.configValue(),
        configInDatum,
      ),
    )

  let oracleIn =
    t.test_input(
      rref,
      t.test_output(
        t.test_script_address(t.oracleValHash),
        t.oracleValue(),
        oInDatum,
      ),
    )

  let oracleOut =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      t.oracleValue(),
      oOutDatum,
    )

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

  let ctx5 =
    ScriptContext { purpose: t.withPurpose(t.merkelClose), transaction: tx }

  close(t.loanMintHash, t.oracleMintHash, redeemerList, ctx5)?
}

test separate_close_single() {
  let test_owner = #"face"

  // let test_user = #"cafe"
  let oref1 = t.test_oref(#"face", 1)
  let cref1 = t.test_oref(#"cafe", 2)
  let rref = t.test_oref(#"dead", 6)
  let uref1 = t.test_oref(#"beef", 4)
  let href1 = t.test_oref(#"feed", 3)

  // let loanAction = tx.merkelLoanAction(2)
  let configDatum =
    tx.mConfigDatum(
      t.merkelLoanSpend,
      t.collateralValHash,
      t.rewardsMintHash,
      t.oracleValHash,
      [t.merkelLoanBalance, t.merkelLoanLiquidate, t.merkelLoanClose],
      [
        t.merkelCollateralBalance,
        t.merkelCollateralLiquidate,
        t.merkelCollateralClose,
      ],
    )
  let configInDatum = InlineDatum(configDatum)

  let loanDatum1 = tx.loanDatum(0, 15, 1000, 0, 1111111114)
  let loanInDatum = InlineDatum(loanDatum1)
  let loanInValue = t.loanTokenValue()

  let loanDatum2 = tx.loanDatum(0, 15, 1000, 0, 1111111115)

  let collateralDatum1 = tx.collateralDatum(0, 12)
  let colInDatum = InlineDatum(collateralDatum1)
  let colInValue = value.merge(t.makeAdaValue(2000), t.loanTokenValue())

  let collateralDatum2 = tx.collateralDatum(1000, 12)

  let oracleInDatum = tx.oracleDatum(2, 11111112, 15, 2)
  let oracleOutDatum = tx.oracleDatum(2, 11111114, 15, 2)

  let oInDatum = InlineDatum(oracleInDatum)
  let oOutDatum = InlineDatum(oracleOutDatum)

  let noDatum = NoDatum

  let withdraw0 =
    dict.from_ascending_list(
      [
        (t.create_stake_credential(t.merkelLoanClose), 0),
        (t.create_stake_credential(t.merkelCollateralClose), 0),
      ],
      t.stakeCompare,
    )

  let loanRedeemer =
    [0]

  let collateralRedeemer =
    [3]

  let loanIn1 =
    t.test_input(
      oref1,
      t.test_output(
        t.test_script_address(t.merkelLoanSpend),
        loanInValue,
        loanInDatum,
      ),
    )

  let colIn1 =
    t.test_input(
      href1,
      t.test_output(
        t.test_script_address(t.collateralValHash),
        colInValue,
        colInDatum,
      ),
    )

  let userIn1 =
    t.test_input(
      uref1,
      t.test_output(t.test_address(#"cafe"), t.makeAdaValue(2010), noDatum),
    )

  let configIn =
    t.test_input(
      cref1,
      t.test_output(
        t.test_script_address(t.configValHash),
        t.configValue(),
        configInDatum,
      ),
    )

  let oracleIn =
    t.test_input(
      rref,
      t.test_output(
        t.test_script_address(t.oracleValHash),
        t.oracleValue(),
        oInDatum,
      ),
    )

  let oracleOut =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      t.oracleValue(),
      oOutDatum,
    )

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

  let ctx1 =
    ScriptContext { purpose: t.withPurpose(t.merkelLoanClose), transaction: tx }

  let ctx2 =
    ScriptContext {
      purpose: t.withPurpose(t.merkelCollateralClose),
      transaction: tx,
    }

  collateralClose(
    t.merkelCollateralSpend,
    t.loanMintHash,
    t.oracleMintHash,
    collateralRedeemer,
    ctx2,
  )? && loanClose(
    t.merkelLoanSpend,
    t.loanMintHash,
    t.oracleMintHash,
    loanRedeemer,
    ctx1,
  )?
}

test merkel_close_multi() {
  let test_owner = #"face"

  // let test_user = #"cafe"
  let oref1 = t.test_oref(#"face", 1)
  let oref2 = t.test_oref(#"face", 2)
  let oref3 = t.test_oref(#"face", 3)
  let cref1 = t.test_oref(#"cafe", 2)
  let rref = t.test_oref(#"dead", 6)
  let uref1 = t.test_oref(#"beef", 4)
  let href1 = t.test_oref(#"feed", 3)
  let href2 = t.test_oref(#"feed", 2)
  let href3 = t.test_oref(#"feed", 1)

  // let loanAction = tx.merkelLoanAction(2)
  let configDatum =
    tx.mConfigDatum(
      t.merkelLoanSpend,
      t.collateralValHash,
      t.rewardsMintHash,
      t.oracleValHash,
      [t.merkelLoanBalance, t.merkelLoanLiquidate, t.merkelLoanClose],
      [
        t.merkelCollateralBalance,
        t.merkelBalance,
        t.merkelLiquidate,
        t.merkelClose,
      ],
    )
  let configInDatum = InlineDatum(configDatum)

  let loanDatum1 = tx.loanDatum(0, 15, 1000, 0, 1111111114)
  let loanInDatum = InlineDatum(loanDatum1)
  let loanInValue = t.loanTokenValue()

  let loanDatum2 = tx.loanDatum(0, 15, 1000, 0, 1111111115)

  let collateralDatum1 = tx.collateralDatum(0, 12)
  let colInDatum = InlineDatum(collateralDatum1)
  let colInValue = t.loanTokenValue()

  let collateralDatum2 = tx.collateralDatum(1000, 12)

  let oracleInDatum = tx.oracleDatum(2, 11111112, 15, 2)
  let oracleOutDatum = tx.oracleDatum(2, 11111114, 15, 2)

  let oInDatum = InlineDatum(oracleInDatum)
  let oOutDatum = InlineDatum(oracleOutDatum)

  let noDatum = NoDatum

  let withdraw0 =
    dict.from_ascending_list(
      [(t.create_stake_credential(t.merkelClose), 0)],
      t.stakeCompare,
    )

  let redeemerList =
    [(0, 5), (1, 6), (2, 7)]

  let loanIn1 =
    t.test_input(
      oref1,
      t.test_output(t.test_script_address(t.mLoan), loanInValue, loanInDatum),
    )

  let loanIn2 =
    t.test_input(
      oref2,
      t.test_output(t.test_script_address(t.mLoan), loanInValue, loanInDatum),
    )

  let loanIn3 =
    t.test_input(
      oref3,
      t.test_output(t.test_script_address(t.mLoan), loanInValue, loanInDatum),
    )

  let colIn1 =
    t.test_input(
      href1,
      t.test_output(t.test_script_address(t.mCol), colInValue, colInDatum),
    )

  let colIn2 =
    t.test_input(
      href2,
      t.test_output(t.test_script_address(t.mCol), colInValue, colInDatum),
    )

  let colIn3 =
    t.test_input(
      href3,
      t.test_output(t.test_script_address(t.mCol), colInValue, colInDatum),
    )

  let userIn1 =
    t.test_input(
      uref1,
      t.test_output(t.test_address(#"cafe"), t.makeAdaValue(2010), noDatum),
    )

  let configIn =
    t.test_input(
      cref1,
      t.test_output(
        t.test_script_address(t.configValHash),
        t.configValue(),
        configInDatum,
      ),
    )

  let oracleIn =
    t.test_input(
      rref,
      t.test_output(
        t.test_script_address(t.oracleValHash),
        t.oracleValue(),
        oInDatum,
      ),
    )

  let oracleOut =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      t.oracleValue(),
      oOutDatum,
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
      outputs: [oracleOut],
      mint: value.to_minted_value(t.loanBurnValue()),
      withdrawals: withdraw0,
    }

  let ctx5 =
    ScriptContext { purpose: t.withPurpose(t.merkelClose), transaction: tx }

  close(t.loanMintHash, t.oracleMintHash, redeemerList, ctx5)?
}

test separate_close_multi() {
  let test_owner = #"face"

  // let test_user = #"cafe"
  let oref1 = t.test_oref(#"face", 1)
  let oref2 = t.test_oref(#"face", 2)
  let oref3 = t.test_oref(#"face", 3)
  let cref1 = t.test_oref(#"cafe", 2)
  let rref = t.test_oref(#"dead", 6)
  let uref1 = t.test_oref(#"beef", 4)
  let href1 = t.test_oref(#"feed", 3)
  let href2 = t.test_oref(#"feed", 2)
  let href3 = t.test_oref(#"feed", 1)

  // let loanAction = tx.merkelLoanAction(2)
  let configDatum =
    tx.mConfigDatum(
      t.merkelLoanSpend,
      t.collateralValHash,
      t.rewardsMintHash,
      t.oracleValHash,
      [t.merkelLoanBalance, t.merkelLoanLiquidate, t.merkelLoanClose],
      [
        t.merkelCollateralBalance,
        t.merkelCollateralLiquidate,
        t.merkelCollateralClose,
      ],
    )
  let configInDatum = InlineDatum(configDatum)

  let loanDatum1 = tx.loanDatum(0, 15, 1000, 0, 1111111114)
  let loanInDatum = InlineDatum(loanDatum1)
  let loanInValue = t.loanTokenValue()

  let loanDatum2 = tx.loanDatum(0, 15, 1000, 0, 1111111115)

  let collateralDatum1 = tx.collateralDatum(0, 12)
  let colInDatum = InlineDatum(collateralDatum1)
  let colInValue = value.merge(t.makeAdaValue(2000), t.loanTokenValue())

  let collateralDatum2 = tx.collateralDatum(1000, 12)

  let oracleInDatum = tx.oracleDatum(2, 11111112, 15, 2)
  let oracleOutDatum = tx.oracleDatum(2, 11111114, 15, 2)

  let oInDatum = InlineDatum(oracleInDatum)
  let oOutDatum = InlineDatum(oracleOutDatum)

  let noDatum = NoDatum

  let withdraw0 =
    dict.from_ascending_list(
      [
        (t.create_stake_credential(t.merkelLoanClose), 0),
        (t.create_stake_credential(t.merkelCollateralClose), 0),
      ],
      t.stakeCompare,
    )

  let loanRedeemer =
    [0, 1, 2]

  let collateralRedeemer =
    [5, 6, 7]

  let loanIn1 =
    t.test_input(
      oref1,
      t.test_output(t.test_script_address(t.mLoan), loanInValue, loanInDatum),
    )

  let loanIn2 =
    t.test_input(
      oref2,
      t.test_output(t.test_script_address(t.mLoan), loanInValue, loanInDatum),
    )

  let loanIn3 =
    t.test_input(
      oref3,
      t.test_output(t.test_script_address(t.mLoan), loanInValue, loanInDatum),
    )

  let colIn1 =
    t.test_input(
      href1,
      t.test_output(t.test_script_address(t.mCol), colInValue, colInDatum),
    )

  let colIn2 =
    t.test_input(
      href2,
      t.test_output(t.test_script_address(t.mCol), colInValue, colInDatum),
    )

  let colIn3 =
    t.test_input(
      href3,
      t.test_output(t.test_script_address(t.mCol), colInValue, colInDatum),
    )

  let userIn1 =
    t.test_input(
      uref1,
      t.test_output(t.test_address(#"cafe"), t.makeAdaValue(2010), noDatum),
    )

  let configIn =
    t.test_input(
      cref1,
      t.test_output(
        t.test_script_address(t.configValHash),
        t.configValue(),
        configInDatum,
      ),
    )

  let oracleIn =
    t.test_input(
      rref,
      t.test_output(
        t.test_script_address(t.oracleValHash),
        t.oracleValue(),
        oInDatum,
      ),
    )

  let oracleOut =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      t.oracleValue(),
      oOutDatum,
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
      outputs: [oracleOut],
      mint: value.to_minted_value(t.loanBurnValue()),
      withdrawals: withdraw0,
    }

  let ctx1 =
    ScriptContext { purpose: t.withPurpose(t.merkelLoanClose), transaction: tx }

  let ctx2 =
    ScriptContext {
      purpose: t.withPurpose(t.merkelCollateralClose),
      transaction: tx,
    }

  collateralClose(
    t.merkelCollateralSpend,
    t.loanMintHash,
    t.oracleMintHash,
    collateralRedeemer,
    ctx2,
  )? && loanClose(
    t.merkelLoanSpend,
    t.loanMintHash,
    t.oracleMintHash,
    loanRedeemer,
    ctx1,
  )?
}
