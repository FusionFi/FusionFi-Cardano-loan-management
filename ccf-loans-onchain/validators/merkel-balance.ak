use aiken/dict
use aiken/list
use aiken/transaction.{
  InlineDatum, Input, NoDatum, Output, ScriptContext, Transaction, WithdrawFrom,
  placeholder,
}
use aiken/transaction/credential.{Inline, ScriptCredential}
use aiken/transaction/value.{PolicyId}
use ccfl/helpers.{merkelTx, withBurn, withdraw4}
use ccfl/types.{
  CollateralDatum, LoanDatum, MerkelCollateralAction, MerkelConfigDatum,
  MerkelLoanAction, OracleDatum, ScriptHash,
}
use tests/tools as t
use tests/transactions as tx

// staking validators that check the full transaction scope.

// Merkel Balance validates the whole transaction for the Balance redeemer case
// it combines both the merkel-loan && merkel-collateral cases together

validator(cp: PolicyId) {
  fn mCol(_d: CollateralDatum, r: MerkelCollateralAction, c: ScriptContext) {
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
      cDatum.collateralRedeemers // I am putting the merkelBalance Hash in loan Redeemers so i dont nede to write another config to test
        |> list.at(r.i)

    dict.has_key(withdrawals, Inline(ScriptCredential(stakeVal)))
  }
}

validator(cp: PolicyId) {
  // this should be in the config datum instead
  fn mLoan(_d: LoanDatum, r: MerkelLoanAction, c: ScriptContext) {
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
      cDatum.collateralRedeemers
        |> list.at(r.i)

    dict.has_key(withdrawals, Inline(ScriptCredential(stakeVal)))
  }
}

validator(p: PolicyId, cp: PolicyId) {
  fn balance(r: List<(Int, Int)>, c: ScriptContext) {
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

    let exchangeRate = rDatum.usdAda

    expect Some(configIn) =
      list.find(
        reference_inputs,
        fn(input) { list.has(value.policies(input.output.value), cp) },
      )

    expect InlineDatum(datum) = configIn.output.datum
    expect cDatum: MerkelConfigDatum = datum

    merkelTx(
      fn(loan, collateral) {
        expect Some(loanToken) =
          list.head(value.flatten(value.without_lovelace(loan.value)))

        expect InlineDatum(datum) = loan.datum
        expect loanDatum: LoanDatum = datum

        expect InlineDatum(datum) = collateral.datum
        expect colDatum: CollateralDatum = datum

        expect Some(loanIn) =
          list.find(
            inputs,
            fn(in) {
              in.output.address.payment_credential == loan.address.payment_credential && value.flatten(
                value.without_lovelace(in.output.value),
              ) == [loanToken]
            },
          )

        expect InlineDatum(datum) = loanIn.output.datum
        expect lin: LoanDatum = datum

        expect Some(colIn) =
          list.find(
            inputs,
            fn(in) {
              in.output.address.payment_credential == loan.address.payment_credential && value.flatten(
                value.without_lovelace(in.output.value),
              ) == [loanToken]
            },
          )

        expect InlineDatum(datum) = colIn.output.datum
        expect cin: CollateralDatum = datum

        let adaOut = value.lovelace_of(collateral.value) / 1000000

        let minCollateralValue = loanDatum.amount * exchangeRate * ( 50 / 100 )

        loanDatum.amount == lin.amount && loanDatum.interest == lin.interest && loanDatum.term == lin.term && adaOut >= minCollateralValue && colDatum.amount == value.lovelace_of(
          collateral.value,
        ) / exchangeRate / 1000000 && list.has(
          value.flatten(collateral.value),
          loanToken,
        ) && value.flatten(value.without_lovelace(loan.value)) == value.flatten(
          value.without_lovelace(collateral.value),
        )
      },
      r,
      outputs,
    )
    // collateral out == exchange * loan * 2
    // coll out credential
    // laon out credential
  }
}

//                 //
// Validator Tests //
//                 //

validator(colVal: ScriptHash, lp: PolicyId, op: PolicyId, cp: PolicyId) {
  fn colBalance(r: List<(Int, Int)>, c: ScriptContext) {
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

        let minCollateralValue = lDatum.amount * exchangeRate * ( 50 / 100 )

        expect list.has(value.policies(output.value), lp)

        expect InlineDatum(datum) = output.datum
        expect outDatum: CollateralDatum = datum

        input.address.payment_credential == output.address.payment_credential && adaOut >= minCollateralValue && outDatum.amount == value.lovelace_of(
          output.value,
        ) / exchangeRate / 1000000 && list.has(
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

test merkel_balance_single() {
  let test_owner = #"face"

  // let test_user = #"cafe"
  let oref1 = t.test_oref(#"face", 1)
  let cref1 = t.test_oref(#"cafe", 2)
  let rref = t.test_oref(#"dead", 6)
  let uref1 = t.test_oref(#"beef", 4)
  let href1 = t.test_oref(#"feed", 3)

  // let collateralAction = tx.merkelCollateralAction(0)
  let configDatum =
    tx.mConfigDatum(
      t.merkelLoanSpend,
      t.merkelCollateralSpend,
      t.rewardsMintHash,
      t.oracleValHash,
      [t.merkelLoanBalance, t.merkelLoanLiquidate, t.merkelLoanClose],
      [t.merkelCollateralBalance, t.merkelBalance],
    )
  let configInDatum = InlineDatum(configDatum)

  let loanDatum1 = tx.loanDatum(1000, 15, 1000, 0, 1111111114)
  let loanInDatum = InlineDatum(loanDatum1)
  let loanInValue = t.loanTokenValue()

  let loanDatum2 = tx.loanDatum(1000, 15, 1000, 0, 1111111115)
  let loanOutDatum = InlineDatum(loanDatum2)
  let loanOutValue = t.loanTokenValue()

  let collateralDatum1 = tx.collateralDatum(1000, 12)
  let colInDatum = InlineDatum(collateralDatum1)
  let colInValue = value.merge(t.makeAdaValue(2000), t.loanTokenValue())

  let collateralDatum2 = tx.collateralDatum(1000, 12)
  let colOutDatum = InlineDatum(collateralDatum2)
  let colOutValue = value.merge(t.makeAdaValue(2000), t.loanTokenValue())

  let oracleInDatum = tx.oracleDatum(2, 11111112, 15, 2)
  let oracleOutDatum = tx.oracleDatum(2, 11111114, 15, 2)

  let oInDatum = InlineDatum(oracleInDatum)
  let oOutDatum = InlineDatum(oracleOutDatum)

  let noDatum = NoDatum

  let withdraw0 =
    dict.from_ascending_list(
      [(t.create_stake_credential(t.merkelCollateralBalance), 0)],
      t.stakeCompare,
    )

  let bRedeemer =
    [(1, 0)]

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

  let loanOut1 =
    t.test_output(t.test_script_address(t.mLoan), loanOutValue, loanOutDatum)

  let colOut1 =
    t.test_output(t.test_script_address(t.mCol), colOutValue, colOutDatum)

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [colIn1, loanIn1, oracleIn, userIn1],
      outputs: [colOut1, loanOut1, oracleOut],
      withdrawals: withdraw0,
    }

  let ctx1 =
    ScriptContext { purpose: t.withPurpose(t.merkelBalance), transaction: tx }

  balance(t.oracleMintHash, t.configMintHash, bRedeemer, ctx1)?
}

test separate_balance_single() {
  let test_owner = #"face"

  // let test_user = #"cafe"
  let oref1 = t.test_oref(#"face", 1)
  let cref1 = t.test_oref(#"cafe", 2)
  let rref = t.test_oref(#"dead", 6)
  let uref1 = t.test_oref(#"beef", 4)
  let href1 = t.test_oref(#"feed", 3)

  // let collateralAction = tx.merkelCollateralAction(0)
  let configDatum =
    tx.mConfigDatum(
      t.merkelLoanSpend,
      t.merkelCollateralSpend,
      t.rewardsMintHash,
      t.oracleValHash,
      [t.merkelLoanBalance, t.merkelLoanLiquidate, t.merkelLoanClose],
      [t.merkelCollateralBalance],
    )
  let configInDatum = InlineDatum(configDatum)

  let loanDatum1 = tx.loanDatum(1000, 15, 1000, 0, 1111111114)
  let loanInDatum = InlineDatum(loanDatum1)
  let loanInValue = t.loanTokenValue()

  let loanDatum2 = tx.loanDatum(1000, 15, 1000, 0, 1111111115)
  let loanOutDatum = InlineDatum(loanDatum2)
  let loanOutValue = t.loanTokenValue()

  let collateralDatum1 = tx.collateralDatum(1000, 12)
  let colInDatum = InlineDatum(collateralDatum1)
  let colInValue = value.merge(t.makeAdaValue(2000), t.loanTokenValue())

  let collateralDatum2 = tx.collateralDatum(1000, 12)
  let colOutDatum = InlineDatum(collateralDatum2)
  let colOutValue = value.merge(t.makeAdaValue(2000), t.loanTokenValue())

  let oracleInDatum = tx.oracleDatum(2, 11111112, 15, 2)
  let oracleOutDatum = tx.oracleDatum(2, 11111114, 15, 2)

  let oInDatum = InlineDatum(oracleInDatum)
  let oOutDatum = InlineDatum(oracleOutDatum)

  let noDatum = NoDatum

  let withdraw0 =
    dict.from_ascending_list(
      [(t.create_stake_credential(t.merkelCollateralBalance), 0)],
      t.stakeCompare,
    )

  let colRedeemer =
    [(0, 0)]

  let loanRedeemer =
    [(1, 1)]

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
        t.test_script_address(t.merkelCollateralSpend),
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

  let colOut1 =
    t.test_output(
      t.test_script_address(t.merkelCollateralSpend),
      colOutValue,
      colOutDatum,
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

  let ctx1 =
    ScriptContext {
      purpose: t.withPurpose(t.merkelCollateralBalance),
      transaction: tx,
    }
  let ctx2 =
    ScriptContext {
      purpose: t.withPurpose(t.merkelLoanBalance),
      transaction: tx,
    }

  colBalance(
    t.merkelCollateralSpend,
    t.loanMintHash,
    t.oracleMintHash,
    t.configMintHash,
    colRedeemer,
    ctx1,
  )? && loanBalance(
    t.merkelLoanSpend,
    t.loanMintHash,
    t.oracleMintHash,
    t.configMintHash,
    loanRedeemer,
    ctx2,
  )?
}
