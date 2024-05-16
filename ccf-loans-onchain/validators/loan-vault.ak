use aiken/list.{filter, find, has, head}
use aiken/transaction.{
  InlineDatum, Input, NoDatum, Output, ScriptContext, Spend, Transaction,
  find_input, placeholder,
}
use aiken/transaction/credential.{ScriptCredential}
use aiken/transaction/value.{
  PolicyId, flatten, lovelace_of, policies, without_lovelace,
}
use ccfl/helpers.{get_own_singleton_output}
use ccfl/types.{
  CollateralDatum, ConfigDatum, LoanAction, LoanDatum, OracleDatum, SLBalance,
  SLClose, SLLiquidate,
}
use tests/tools as t
use tests/transactions as tx

//                     //
// Separate Loan Vault //
//                     //

// Loan Vault holds the loan information at a token utxo

validator(op: PolicyId, lp: PolicyId, cp: PolicyId) {
  fn loanVal(d: LoanDatum, r: LoanAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Spend(oref) = purpose

    let Transaction { inputs, outputs, reference_inputs, .. } = transaction

    expect Some(oracleOut) =
      find(outputs, fn(output) { has(policies(output.value), op) })

    expect InlineDatum(datum) = oracleOut.datum
    expect rDatum: OracleDatum = datum

    let exchangeRate = rDatum.usdAda

    expect Some(configIn) =
      find(
        reference_inputs,
        fn(input) { has(policies(input.output.value), cp) },
      )

    expect InlineDatum(datum) = configIn.output.datum
    expect cDatum: ConfigDatum = datum

    when r is {
      SLBalance -> {
        expect Some(ownIn) = find_input(inputs, oref)

        expect Some(loanToken) =
          head(flatten(without_lovelace(ownIn.output.value)))

        expect Some(colOut) =
          find(
            outputs,
            fn(output) {
              expect Some(colToken) =
                head(flatten(without_lovelace(output.value)))

              output.address.payment_credential == ScriptCredential(
                cDatum.colVal,
              ) && loanToken == colToken
            },
          )

        expect InlineDatum(datum) = colOut.datum
        expect cDatum: CollateralDatum = datum

        let ownOutputs =
          filter(
            outputs,
            fn(output) {
              ownIn.output.address.payment_credential == output.address.payment_credential
            },
          )

        expect Some(ownOut) =
          find(
            ownOutputs,
            fn(output) {
              expect Some(outValue) =
                head(flatten(without_lovelace(output.value)))
              loanToken == outValue
            },
          )

        let adaOut = lovelace_of(colOut.value) / 1000000

        // let newCollateralValue = adaOut / exchangeRate
        let minCollateralValue = d.amount * exchangeRate * ( 50 / 100 )

        expect has(policies(ownOut.value), lp)

        expect InlineDatum(datum) = ownOut.datum
        expect datum: LoanDatum = datum

        datum.amount == d.amount && datum.interest == d.interest && datum.term == d.term && adaOut >= minCollateralValue
      }

      SLLiquidate -> {
        // Liquidate Loan

        expect Some(ownIn) = find_input(inputs, oref)

        expect Some(loanToken) =
          head(flatten(without_lovelace(ownIn.output.value)))

        expect Some(colOut) =
          find(
            outputs,
            fn(output) {
              expect Some(colToken) =
                head(flatten(without_lovelace(output.value)))

              output.address.payment_credential == ScriptCredential(
                cDatum.colVal,
              ) && loanToken == colToken
            },
          )

        expect InlineDatum(datum) = colOut.datum
        expect cDatum: CollateralDatum = datum

        let ownOutputs =
          filter(
            outputs,
            fn(output) {
              ownIn.output.address.payment_credential == output.address.payment_credential
            },
          )

        expect Some(ownOut) =
          find(
            ownOutputs,
            fn(output) {
              expect Some(outValue) =
                head(flatten(without_lovelace(output.value)))
              loanToken == outValue
            },
          )

        let adaOut = lovelace_of(colOut.value) / 1000000

        expect has(policies(ownOut.value), lp)

        expect InlineDatum(datum) = ownOut.datum
        expect datum: LoanDatum = datum

        let minCollateralValue = datum.amount * exchangeRate * ( 85 / 100 )

        datum.amount == cDatum.amount && datum.interest == d.interest && datum.term == d.term && adaOut >= minCollateralValue
      }
      // close
      SLClose -> d.amount == 0
    }
  }
}

// Loan Validator Tests
test loan_liquidate() {
  let test_owner = #"face"

  // let test_user = #"cafe"
  let oref1 = t.test_oref(#"face", 1)
  let oref2 = t.test_oref(#"face", 2)
  let oref3 = t.test_oref(#"face", 3)
  // let oref4 = t.test_oref(#"face", 4)
  let cref1 = t.test_oref(#"cafe", 2)
  let rref = t.test_oref(#"dead", 6)
  let uref1 = t.test_oref(#"beef", 4)
  // let uref2 = t.test_oref(#"beef", 5)
  // let uref3 = t.test_oref(#"beef", 1)
  // let uref4 = t.test_oref(#"beef", 2)
  let href1 = t.test_oref(#"feed", 3)
  let href2 = t.test_oref(#"feed", 2)
  let href3 = t.test_oref(#"feed", 1)
  let href4 = t.test_oref(#"feed", 4)

  let loanAction = tx.loanActionLiquidate()

  let configDatum =
    tx.configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
  let configInDatum = InlineDatum(configDatum)

  let configInDatum = InlineDatum(configDatum)

  let loanDatum1 = tx.loanDatum(1000, 15, 1000, 0, 1111111114)
  let loanInDatum = InlineDatum(loanDatum1)
  let loanInValue = t.loanTokenValue()

  let loanDatum2 = tx.loanDatum(0, 15, 1000, 0, 1111111115)
  let loanOutDatum = InlineDatum(loanDatum2)
  let loanOutValue = t.loanTokenValue()

  let collateralDatum1 = tx.collateralDatum(2000, 12)
  let colInDatum = InlineDatum(collateralDatum1)
  let colInValue = value.merge(t.makeAdaValue(2000), t.loanTokenValue())

  let collateralDatum2 = tx.collateralDatum(0, 12)
  let colOutDatum = InlineDatum(collateralDatum2)
  let colOutValue = value.merge(t.makeAdaValue(2), t.loanTokenValue())

  let oracleInDatum = tx.oracleDatum(2, 11111112, 15, 2)
  let oracleOutDatum = tx.oracleDatum(2, 11111114, 15, 2)

  let oInDatum = InlineDatum(oracleInDatum)
  let oOutDatum = InlineDatum(oracleOutDatum)

  let noDatum = NoDatum

  let loanIn1 =
    t.test_input(
      oref1,
      t.test_output(
        t.test_script_address(t.loanValHash),
        loanInValue,
        loanInDatum,
      ),
    )

  let loanIn2 =
    t.test_input(
      oref2,
      t.test_output(
        t.test_script_address(t.loanValHash),
        loanInValue,
        loanInDatum,
      ),
    )

  let loanIn3 =
    t.test_input(
      oref3,
      t.test_output(
        t.test_script_address(t.loanValHash),
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

  let loanOut1 =
    t.test_output(
      t.test_script_address(t.loanValHash),
      loanOutValue,
      loanOutDatum,
    )

  let loanOut2 =
    t.test_output(
      t.test_script_address(t.loanValHash),
      loanOutValue,
      loanOutDatum,
    )

  let loanOut3 =
    t.test_output(
      t.test_script_address(t.loanValHash),
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
    }

  let ctx1 = ScriptContext { purpose: Spend(oref1), transaction: tx }
  let ctx2 = ScriptContext { purpose: Spend(oref2), transaction: tx }
  let ctx3 = ScriptContext { purpose: Spend(oref3), transaction: tx }

  loanVal(
    t.oracleMintHash,
    t.loanMintHash,
    t.configMintHash,
    loanDatum1,
    loanAction,
    ctx1,
  )? && loanVal(
    t.oracleMintHash,
    t.loanMintHash,
    t.configMintHash,
    loanDatum1,
    loanAction,
    ctx2,
  )? && loanVal(
    t.oracleMintHash,
    t.loanMintHash,
    t.configMintHash,
    loanDatum1,
    loanAction,
    ctx3,
  )?
}

test loan_close() {
  let test_owner = #"face"

  // let test_user = #"cafe"
  let oref1 = t.test_oref(#"face", 1)
  let oref2 = t.test_oref(#"face", 2)
  let oref3 = t.test_oref(#"face", 3)
  // let oref4 = t.test_oref(#"face", 4)
  let cref1 = t.test_oref(#"cafe", 2)
  let rref = t.test_oref(#"dead", 6)
  let uref1 = t.test_oref(#"beef", 4)
  // let uref2 = t.test_oref(#"beef", 5)
  // let uref3 = t.test_oref(#"beef", 1)
  // let uref4 = t.test_oref(#"beef", 2)
  let href1 = t.test_oref(#"feed", 3)
  let href2 = t.test_oref(#"feed", 2)
  let href3 = t.test_oref(#"feed", 1)
  let href4 = t.test_oref(#"feed", 4)

  let loanAction = tx.loanActionClose()

  let configDatum =
    tx.configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
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

  let loanIn1 =
    t.test_input(
      oref1,
      t.test_output(
        t.test_script_address(t.loanValHash),
        loanInValue,
        loanInDatum,
      ),
    )

  let loanIn2 =
    t.test_input(
      oref2,
      t.test_output(
        t.test_script_address(t.loanValHash),
        loanInValue,
        loanInDatum,
      ),
    )

  let loanIn3 =
    t.test_input(
      oref3,
      t.test_output(
        t.test_script_address(t.loanValHash),
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
    }

  let ctx1 = ScriptContext { purpose: Spend(oref1), transaction: tx }
  let ctx2 = ScriptContext { purpose: Spend(oref2), transaction: tx }
  let ctx3 = ScriptContext { purpose: Spend(oref3), transaction: tx }

  loanVal(
    t.oracleMintHash,
    t.loanMintHash,
    t.configMintHash,
    loanDatum1,
    loanAction,
    ctx1,
  )? && loanVal(
    t.oracleMintHash,
    t.loanMintHash,
    t.configMintHash,
    loanDatum1,
    loanAction,
    ctx2,
  )? && loanVal(
    t.oracleMintHash,
    t.loanMintHash,
    t.configMintHash,
    loanDatum1,
    loanAction,
    ctx3,
  )?
  // loanVal(
  //   t.merkelLoanSpend,
  //   t.loanMintHash,
  //   t.oracleMintHash,
  //   redeemerList,
  //   ctx5,
  // )?
}

test multi_balance() {
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
  let href4 = t.test_oref(#"feed", 4)

  let loanAction = tx.loanActionBalance()

  // let loanMintedValue =
  //   value.to_minted_value(value.merge(t.loanTokenValue(), t.loanTokenValue()))
  let configDatum =
    tx.configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
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

  let loanIn1 =
    t.test_input(
      oref1,
      t.test_output(
        t.test_script_address(t.loanValHash),
        loanInValue,
        loanInDatum,
      ),
    )

  let loanIn2 =
    t.test_input(
      oref2,
      t.test_output(
        t.test_script_address(t.loanValHash),
        loanInValue,
        loanInDatum,
      ),
    )

  let loanIn3 =
    t.test_input(
      oref3,
      t.test_output(
        t.test_script_address(t.loanValHash),
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

  let userIn =
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
      t.test_script_address(t.loanValHash),
      loanOutValue,
      loanOutDatum,
    )

  let loanOut2 =
    t.test_output(
      t.test_script_address(t.loanValHash),
      loanOutValue,
      loanOutDatum,
    )

  let loanOut3 =
    t.test_output(
      t.test_script_address(t.loanValHash),
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
        userIn,
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
    }

  let ctx1 = ScriptContext { purpose: Spend(oref1), transaction: tx }
  let ctx2 = ScriptContext { purpose: Spend(oref2), transaction: tx }
  let ctx3 = ScriptContext { purpose: Spend(oref3), transaction: tx }

  loanVal(
    t.oracleMintHash,
    t.loanMintHash,
    t.configMintHash,
    loanDatum1,
    loanAction,
    ctx1,
  )? && loanVal(
    t.oracleMintHash,
    t.loanMintHash,
    t.configMintHash,
    loanDatum1,
    loanAction,
    ctx2,
  )? && loanVal(
    t.oracleMintHash,
    t.loanMintHash,
    t.configMintHash,
    loanDatum1,
    loanAction,
    ctx3,
  )?
}

test single_balance() {
  let test_owner = #"face"

  // let test_user = #"cafe"
  let oref = t.test_oref(#"face", 1)
  let cref = t.test_oref(#"cafe", 2)
  let rref = t.test_oref(#"dead", 6)
  let uref = t.test_oref(#"beef", 4)
  let href = t.test_oref(#"feed", 3)

  let loanAction = tx.loanActionBalance()

  // let loanMintedValue =
  //   value.to_minted_value(value.merge(t.loanTokenValue(), t.loanTokenValue()))
  let configDatum =
    tx.configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
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

  let loanIn =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(t.loanValHash),
        loanInValue,
        loanInDatum,
      ),
    )

  let colIn =
    t.test_input(
      href,
      t.test_output(
        t.test_script_address(t.collateralValHash),
        colInValue,
        colInDatum,
      ),
    )

  let userIn =
    t.test_input(
      uref,
      t.test_output(t.test_address(#"cafe"), t.makeAdaValue(2010), noDatum),
    )

  let configIn =
    t.test_input(
      cref,
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

  let loanOut =
    t.test_output(
      t.test_script_address(t.loanValHash),
      loanOutValue,
      loanOutDatum,
    )

  let colOut =
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
      inputs: [oracleIn, userIn, colIn, loanIn],
      outputs: [loanOut, colOut, oracleOut],
    }

  let ctx1 = ScriptContext { purpose: Spend(oref), transaction: tx }

  loanVal(
    t.oracleMintHash,
    t.loanMintHash,
    t.configMintHash,
    loanDatum1,
    loanAction,
    ctx1,
  )?
}
