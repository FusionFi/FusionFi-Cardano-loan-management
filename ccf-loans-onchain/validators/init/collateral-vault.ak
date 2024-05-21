use aiken/dict
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
  CollateralAction, CollateralDatum, ConfigDatum, LoanDatum, OracleDatum,
  SCBalance, SCClose, SCLiquidate,
}
use tests/tools as t
use tests/transactions as tx

//                           //
// Separate Collateral Vault //
//                           //

validator(op: PolicyId, lp: PolicyId, cp: PolicyId) {
  fn collateralVal(
    d: CollateralDatum,
    r: CollateralAction,
    c: ScriptContext,
  ) -> Bool {
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
      SCBalance -> {
        expect Some(ownIn) = find_input(inputs, oref)

        expect Some(collateralToken) =
          head(flatten(without_lovelace(ownIn.output.value)))

        expect Some(loanOut) =
          find(
            outputs,
            fn(output) {
              expect Some(loanToken) =
                head(flatten(without_lovelace(output.value)))

              output.address.payment_credential == ScriptCredential(
                cDatum.loanVal,
              ) && loanToken == collateralToken
            },
          )

        expect InlineDatum(datum) = loanOut.datum
        expect lDatum: LoanDatum = datum

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
              collateralToken == outValue
            },
          )

        let adaOut = lovelace_of(ownOut.value) / 1000000

        // let newCollateralValue = adaOut / exchangeRate
        let minCollateralValue = lDatum.amount * exchangeRate * ( 50 / 100 )

        expect has(flatten(ownOut.value), collateralToken)

        expect InlineDatum(datum) = ownOut.datum
        expect outDatum: CollateralDatum = datum

        adaOut >= minCollateralValue && outDatum.amount <= adaOut / exchangeRate
      }

      SCLiquidate -> {
        expect Some(ownIn) = find_input(inputs, oref)

        expect Some(collateralToken) =
          head(flatten(without_lovelace(ownIn.output.value)))

        expect Some(loanOut) =
          find(
            outputs,
            fn(output) {
              expect Some(loanToken) =
                head(flatten(without_lovelace(output.value)))

              output.address.payment_credential == ScriptCredential(
                cDatum.loanVal,
              ) && loanToken == collateralToken
            },
          )

        expect InlineDatum(datum) = loanOut.datum
        expect lDatum: LoanDatum = datum

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
              collateralToken == outValue
            },
          )

        let adaOut = lovelace_of(ownOut.value) / 1000000

        expect has(flatten(ownOut.value), collateralToken)

        expect InlineDatum(datum) = ownOut.datum
        expect outDatum: CollateralDatum = datum

        let minCollateralValue = lDatum.amount * exchangeRate * ( 85 / 100 )

        adaOut >= minCollateralValue && outDatum.amount <= adaOut / exchangeRate
      }

      SCClose -> {
        expect Some(input) = find_input(inputs, oref)

        let loanTokenVal = value.without_lovelace(input.output.value)
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
          transaction.mint
            |> value.from_minted_value()
            |> value.flatten()

        expect list.has(burns, burnVal)
        d.amount == 0
      }
    }
  }
}

// Collateral Validator Tests
test balance_single() {
  let test_owner = #"face"

  // let test_user = #"cafe"
  let oref = t.test_oref(#"face", 1)
  let cref = t.test_oref(#"cafe", 2)
  let rref = t.test_oref(#"dead", 6)
  let uref = t.test_oref(#"beef", 4)
  let href = t.test_oref(#"feed", 3)

  let collateralAction = tx.collateralActionBalance()

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

  let collateralDatum2 = tx.collateralDatum(500, 12)
  // we need to make sure the amount here is 2x
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
      inputs: [userIn, oracleIn, colIn, loanIn],
      outputs: [loanOut, colOut, oracleOut],
    }

  let ctx = ScriptContext { purpose: Spend(href), transaction: tx }

  collateralVal(
    t.oracleMintHash,
    t.loanMintHash,
    t.configMintHash,
    collateralDatum1,
    collateralAction,
    ctx,
  )?
}

test balance_multi() {
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

  // let href4 = t.test_oref(#"feed", 4)
  let loanAction = tx.collateralActionBalance()

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

  let collateralDatum2 = tx.collateralDatum(500, 12)
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

  let ctx1 = ScriptContext { purpose: Spend(href1), transaction: tx }
  let ctx2 = ScriptContext { purpose: Spend(href2), transaction: tx }
  let ctx3 = ScriptContext { purpose: Spend(href3), transaction: tx }

  collateralVal(
    t.oracleMintHash,
    t.loanMintHash,
    t.configMintHash,
    collateralDatum1,
    loanAction,
    ctx1,
  )? && collateralVal(
    t.oracleMintHash,
    t.loanMintHash,
    t.configMintHash,
    collateralDatum1,
    loanAction,
    ctx2,
  )? && collateralVal(
    t.oracleMintHash,
    t.loanMintHash,
    t.configMintHash,
    collateralDatum1,
    loanAction,
    ctx3,
  )?
}

test liquidate_single() {
  let test_owner = #"face"

  // let test_user = #"cafe"
  let oref1 = t.test_oref(#"face", 1)
  let cref1 = t.test_oref(#"cafe", 2)
  let rref = t.test_oref(#"dead", 6)
  let uref1 = t.test_oref(#"beef", 4)
  let href1 = t.test_oref(#"feed", 3)

  let loanAction = tx.collateralActionLiquidate()

  let configDatum =
    tx.configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)

  // let configInDatum = InlineDatum(configDatum)
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

  let loanOut1 =
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

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [loanIn1, oracleIn, userIn1, colIn1],
      outputs: [loanOut1, oracleOut, colOut1],
    }

  let ctx1 = ScriptContext { purpose: Spend(href1), transaction: tx }

  collateralVal(
    t.oracleMintHash,
    t.loanMintHash,
    t.configMintHash,
    collateralDatum1,
    loanAction,
    ctx1,
  )?
}

test liquidate_multi() {
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

  // let href4 = t.test_oref(#"feed", 4)
  let loanAction = tx.collateralActionLiquidate()

  let configDatum =
    tx.configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)

  // let configInDatum = InlineDatum(configDatum)
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

  let ctx1 = ScriptContext { purpose: Spend(href1), transaction: tx }
  let ctx2 = ScriptContext { purpose: Spend(href2), transaction: tx }
  let ctx3 = ScriptContext { purpose: Spend(href3), transaction: tx }

  collateralVal(
    t.oracleMintHash,
    t.loanMintHash,
    t.configMintHash,
    collateralDatum1,
    loanAction,
    ctx1,
  )? && collateralVal(
    t.oracleMintHash,
    t.loanMintHash,
    t.configMintHash,
    collateralDatum1,
    loanAction,
    ctx2,
  )? && collateralVal(
    t.oracleMintHash,
    t.loanMintHash,
    t.configMintHash,
    collateralDatum1,
    loanAction,
    ctx3,
  )?
}

test close_single() {
  let test_owner = #"face"

  // let test_user = #"cafe"
  let oref1 = t.test_oref(#"face", 1)
  let cref1 = t.test_oref(#"cafe", 2)
  let rref = t.test_oref(#"dead", 6)
  let uref1 = t.test_oref(#"beef", 4)
  let href1 = t.test_oref(#"feed", 3)

  let loanAction = tx.collateralActionClose()

  let configDatum =
    tx.configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
  let configInDatum = InlineDatum(configDatum)

  let loanDatum1 = tx.loanDatum(0, 15, 1000, 0, 1111111114)
  let loanInDatum = InlineDatum(loanDatum1)
  let loanInValue = t.loanTokenValue()

  let loanDatum2 = tx.loanDatum(0, 15, 1000, 0, 1111111115)

  // let loanOutDatum = InlineDatum(loanDatum2)
  // let loanOutValue = t.loanTokenValue()
  let collateralDatum1 = tx.collateralDatum(0, 12)
  let colInDatum = InlineDatum(collateralDatum1)
  let colInValue = value.merge(t.makeAdaValue(2), t.loanTokenValue())

  let collateralDatum2 = tx.collateralDatum(1000, 12)

  // let colOutDatum = InlineDatum(collateralDatum2)
  // let colOutValue = value.merge(t.makeAdaValue(1000), t.loanTokenValue())
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
    }

  let ctx1 = ScriptContext { purpose: Spend(href1), transaction: tx }

  collateralVal(
    t.oracleMintHash,
    t.loanMintHash,
    t.configMintHash,
    collateralDatum1,
    loanAction,
    ctx1,
  )?
}

test close_multi() {
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

  // let href4 = t.test_oref(#"feed", 4)
  let loanAction = tx.collateralActionClose()

  let configDatum =
    tx.configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
  let configInDatum = InlineDatum(configDatum)

  let loanDatum1 = tx.loanDatum(0, 15, 1000, 0, 1111111114)
  let loanInDatum = InlineDatum(loanDatum1)
  let loanInValue = t.loanTokenValue()

  let loanDatum2 = tx.loanDatum(0, 15, 1000, 0, 1111111115)

  // let loanOutDatum = InlineDatum(loanDatum2)
  // let loanOutValue = t.loanTokenValue()
  let collateralDatum1 = tx.collateralDatum(0, 12)
  let colInDatum = InlineDatum(collateralDatum1)
  let colInValue = value.merge(t.makeAdaValue(2), t.loanTokenValue())

  let collateralDatum2 = tx.collateralDatum(1000, 12)

  // let colOutDatum = InlineDatum(collateralDatum2)
  // let colOutValue = value.merge(t.makeAdaValue(1000), t.loanTokenValue())
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

  let ctx1 = ScriptContext { purpose: Spend(href1), transaction: tx }
  let ctx2 = ScriptContext { purpose: Spend(href2), transaction: tx }
  let ctx3 = ScriptContext { purpose: Spend(href3), transaction: tx }

  collateralVal(
    t.oracleMintHash,
    t.loanMintHash,
    t.configMintHash,
    collateralDatum1,
    loanAction,
    ctx1,
  )? && collateralVal(
    t.oracleMintHash,
    t.loanMintHash,
    t.configMintHash,
    collateralDatum1,
    loanAction,
    ctx2,
  )? && collateralVal(
    t.oracleMintHash,
    t.loanMintHash,
    t.configMintHash,
    collateralDatum1,
    loanAction,
    ctx3,
  )?
}
