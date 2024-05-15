use aiken/dict
use aiken/list
use aiken/transaction.{
  InlineDatum, Input, NoDatum, Output, ScriptContext, Transaction, WithdrawFrom,
  placeholder,
}
use aiken/transaction/credential.{Inline, ScriptCredential}
use aiken/transaction/value.{PolicyId}
use ccfl/helpers.{merkel0, withBurn, withdraw4}
use ccfl/types.{
  CollateralDatum, LoanDatum, MerkelConfigDatum, MerkelLoanAction, OracleDatum,
  ScriptHash,
}
use tests/tools as t
use tests/transactions as tx

//                   //
// Merkel Loan Vault //
//                   //

validator(cp: PolicyId) {
  // this should be in the config datum instead
  fn spend(_d: LoanDatum, r: MerkelLoanAction, c: ScriptContext) {
    let ScriptContext { transaction, .. } = c
    let Transaction { reference_inputs, withdrawals, .. } = transaction

    expect Some(configIn) =
      list.find(
        reference_inputs,
        fn(input) { list.has(value.policies(input.output.value), cp) },
      )

    expect InlineDatum(datum) = configIn.output.datum
    expect cDatum: MerkelConfigDatum = datum

    expect Some(stakeVal) =
      cDatum.loanRedeemers
        |> list.at(r.i)

    dict.has_key(withdrawals, Inline(ScriptCredential(stakeVal)))
  }
}

validator(loanVal: ScriptHash, lp: PolicyId, op: PolicyId, cp: PolicyId) {
  fn loanBalance(r: List<(Int, Int)>, c: ScriptContext) {
    expect ScriptContext { transaction, purpose: WithdrawFrom(stake_cred) } = c

    let Transaction { outputs, reference_inputs, .. } = transaction

    expect Inline(ScriptCredential(own_validator)) = stake_cred

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

        // let newCollateralValue = adaOut / exchangeRate
        let minCollateralValue = d.amount * exchangeRate * ( 50 / 100 )

        expect list.has(value.policies(output.value), lp)

        expect InlineDatum(datum) = output.datum
        expect datum: LoanDatum = datum

        input.address.payment_credential == output.address.payment_credential && datum.amount == d.amount && datum.interest == d.interest && datum.term == d.term && adaOut >= minCollateralValue
      },
      loanVal,
      r,
      transaction,
    )
  }
}

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

        input.address.payment_credential == output.address.payment_credential && datum.amount == d.amount && datum.interest == d.interest && datum.term == d.term && adaOut >= minCollateralValue
      },
      loanVal,
      r,
      transaction,
    )
  }
}

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

//                 //
// Validator Tests //
//                 //

test loan_close() {
  let test_owner = #"face"

  // let test_user = #"cafe"
  let oref1 = t.test_oref(#"face", 1)
  let oref2 = t.test_oref(#"face", 2)
  let oref3 = t.test_oref(#"face", 3)
  let oref4 = t.test_oref(#"face", 4)
  let cref1 = t.test_oref(#"cafe", 2)
  let rref = t.test_oref(#"dead", 6)
  let uref1 = t.test_oref(#"beef", 4)
  let uref2 = t.test_oref(#"beef", 5)
  let uref3 = t.test_oref(#"beef", 1)
  let uref4 = t.test_oref(#"beef", 2)
  let href1 = t.test_oref(#"feed", 3)
  let href2 = t.test_oref(#"feed", 2)
  let href3 = t.test_oref(#"feed", 1)
  let href4 = t.test_oref(#"feed", 4)

  let loanAction = tx.merkelLoanAction(2)

  let configDatum =
    tx.mConfigDatum(
      t.merkelLoanSpend,
      t.collateralValHash,
      t.rewardsMintHash,
      t.oracleValHash,
      [t.merkelLoanBalance, t.merkelLoanLiquidate, t.merkelLoanClose],
      [],
    )
  let configInDatum = InlineDatum(configDatum)

  let loanDatum1 = tx.loanDatum(0, 15, 1000, 0, 1111111114)
  let loanInDatum = InlineDatum(loanDatum1)
  let loanInValue = t.loanTokenValue()

  let loanDatum2 = tx.loanDatum(0, 15, 1000, 0, 1111111115)
  let loanOutDatum = InlineDatum(loanDatum2)
  let loanOutValue = t.loanTokenValue()

  let collateralDatum1 = tx.collateralDatum(2000, 12)
  let colInDatum = InlineDatum(collateralDatum1)
  let colInValue = value.merge(t.makeAdaValue(2000), t.loanTokenValue())

  let collateralDatum2 = tx.collateralDatum(1000, 12)
  let colOutDatum = InlineDatum(collateralDatum2)
  let colOutValue = value.merge(t.makeAdaValue(1000), t.loanTokenValue())

  let oracleInDatum = tx.oracleDatum(2, 11111112, 15, 2)
  let oracleOutDatum = tx.oracleDatum(2, 11111114, 15, 2)

  let oInDatum = InlineDatum(oracleInDatum)
  let oOutDatum = InlineDatum(oracleOutDatum)

  let noDatum = NoDatum

  let withdraw0 =
    dict.from_ascending_list(
      [(t.create_stake_credential(t.merkelLoanClose), 0)],
      t.stakeCompare,
    )

  let redeemerList =
    [0, 1, 2]

  let loanIn1 =
    t.test_input(
      oref1,
      t.test_output(
        t.test_script_address(t.merkelLoanSpend),
        loanInValue,
        loanInDatum,
      ),
    )

  let loanIn2 =
    t.test_input(
      oref2,
      t.test_output(
        t.test_script_address(t.merkelLoanSpend),
        loanInValue,
        loanInDatum,
      ),
    )

  let loanIn3 =
    t.test_input(
      oref3,
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

  let colIn2 =
    t.test_input(
      href2,
      t.test_output(
        t.test_script_address(t.collateralValHash),
        colInValue,
        colInDatum,
      ),
    )

  let colIn3 =
    t.test_input(
      href3,
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
    ScriptContext { purpose: t.withPurpose(t.merkelLoanClose), transaction: tx }

  loanClose(
    t.merkelLoanSpend,
    t.loanMintHash,
    t.oracleMintHash,
    redeemerList,
    ctx5,
  )?
}

test loan_balance() {
  let test_owner = #"face"

  // let test_user = #"cafe"
  let oref1 = t.test_oref(#"face", 1)
  let oref2 = t.test_oref(#"face", 2)
  let oref3 = t.test_oref(#"face", 3)
  let oref4 = t.test_oref(#"face", 4)
  let cref1 = t.test_oref(#"cafe", 2)
  let rref = t.test_oref(#"dead", 6)
  let uref1 = t.test_oref(#"beef", 4)
  let uref2 = t.test_oref(#"beef", 5)
  let uref3 = t.test_oref(#"beef", 1)
  let uref4 = t.test_oref(#"beef", 2)
  let href1 = t.test_oref(#"feed", 3)
  let href2 = t.test_oref(#"feed", 2)
  let href3 = t.test_oref(#"feed", 1)
  let href4 = t.test_oref(#"feed", 4)

  let loanAction = tx.merkelLoanAction(0)

  let configDatum =
    tx.mConfigDatum(
      t.merkelLoanSpend,
      t.collateralValHash,
      t.rewardsMintHash,
      t.oracleValHash,
      [t.merkelLoanBalance, t.merkelLoanLiquidate, t.merkelLoanClose],
      [],
    )
  let configInDatum = InlineDatum(configDatum)

  let loanDatum1 = tx.loanDatum(1000, 15, 1000, 0, 1111111114)
  let loanInDatum = InlineDatum(loanDatum1)
  let loanInValue = t.loanTokenValue()

  let loanDatum2 = tx.loanDatum(1000, 15, 1000, 0, 1111111115)
  let loanOutDatum = InlineDatum(loanDatum2)
  let loanOutValue = t.loanTokenValue()

  let collateralDatum1 = tx.collateralDatum(2000, 12)
  let colInDatum = InlineDatum(collateralDatum1)
  let colInValue = value.merge(t.makeAdaValue(2000), t.loanTokenValue())

  let collateralDatum2 = tx.collateralDatum(1000, 12)
  let colOutDatum = InlineDatum(collateralDatum2)
  let colOutValue = value.merge(t.makeAdaValue(1000), t.loanTokenValue())

  let oracleInDatum = tx.oracleDatum(2, 11111112, 15, 2)
  let oracleOutDatum = tx.oracleDatum(2, 11111114, 15, 2)

  let oInDatum = InlineDatum(oracleInDatum)
  let oOutDatum = InlineDatum(oracleOutDatum)

  let noDatum = NoDatum

  let withdraw0 =
    dict.from_ascending_list(
      [(t.create_stake_credential(t.merkelLoanBalance), 0)],
      t.stakeCompare,
    )

  let redeemerList =
    [(0, 0), (1, 1), (2, 2)]

  let loanIn1 =
    t.test_input(
      oref1,
      t.test_output(
        t.test_script_address(t.merkelLoanSpend),
        loanInValue,
        loanInDatum,
      ),
    )

  let loanIn2 =
    t.test_input(
      oref1,
      t.test_output(
        t.test_script_address(t.merkelLoanSpend),
        loanInValue,
        loanInDatum,
      ),
    )

  let loanIn3 =
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

  let colIn2 =
    t.test_input(
      href1,
      t.test_output(
        t.test_script_address(t.collateralValHash),
        colInValue,
        colInDatum,
      ),
    )

  let colIn3 =
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

  let loanOut1 =
    t.test_output(
      t.test_script_address(t.merkelLoanSpend),
      loanOutValue,
      loanOutDatum,
    )

  let loanOut2 =
    t.test_output(
      t.test_script_address(t.merkelLoanSpend),
      loanOutValue,
      loanOutDatum,
    )

  let loanOut3 =
    t.test_output(
      t.test_script_address(t.merkelLoanSpend),
      loanOutValue,
      loanOutDatum,
    )

  let colOut1 =
    t.test_output(
      t.test_script_address(t.collateralValHash),
      colOutValue,
      colOutDatum,
    )

  let colOut2 =
    t.test_output(
      t.test_script_address(t.collateralValHash),
      colOutValue,
      colOutDatum,
    )
  let colOut3 =
    t.test_output(
      t.test_script_address(t.collateralValHash),
      colOutValue,
      colOutDatum,
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

  let ctx5 =
    ScriptContext {
      purpose: t.withPurpose(t.merkelLoanBalance),
      transaction: tx,
    }

  loanBalance(
    t.merkelLoanSpend,
    t.loanMintHash,
    t.oracleMintHash,
    t.configMintHash,
    redeemerList,
    ctx5,
  )?
}
