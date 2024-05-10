use aiken/dict
use aiken/list.{find, has, head}
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
use tests/transactions.{
  collateralActionBalance, collateralDatum, configDatum, loanDatum, oracleDatum,
}

//                           //
// Separate Collateral Vault //
//                           //

validator(op: PolicyId, lp: PolicyId, cp: PolicyId) {
  fn collateralVal(
    _d: CollateralDatum,
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

        let ownOut = get_own_singleton_output(transaction, oref)

        expect InlineDatum(datum) = ownOut.datum
        expect outDatum: CollateralDatum = datum

        lovelace_of(ownOut.value) >= lDatum.amount * exchangeRate * ( 50 / 100 ) * 1000000 && outDatum.amount == lovelace_of(
          ownOut.value,
        ) / exchangeRate / 1000000 && has(
          flatten(ownOut.value),
          collateralToken,
        )
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

        let ownOut = get_own_singleton_output(transaction, oref)

        expect InlineDatum(datum) = ownOut.datum
        expect outDatum: CollateralDatum = datum

        lovelace_of(ownOut.value) >= lDatum.amount * exchangeRate * ( 50 / 100 ) * 1000000 && outDatum.amount == lovelace_of(
          ownOut.value,
        ) / exchangeRate / 1000000 && has(
          flatten(ownOut.value),
          collateralToken,
        )
      }

      SCClose -> True
    }
  }
}

// Collateral Validator Tests
test collateral_val() {
  let test_owner = #"face"

  // let test_user = #"cafe"
  let oref = t.test_oref(#"face", 1)
  let cref = t.test_oref(#"cafe", 2)
  let rref = t.test_oref(#"dead", 6)
  let uref = t.test_oref(#"beef", 4)
  let href = t.test_oref(#"feed", 3)

  let collateralAction = collateralActionBalance()

  // let loanMintedValue =
  //   value.to_minted_value(value.merge(t.loanTokenValue(), t.loanTokenValue()))
  let configDatum =
    configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
  let configInDatum = InlineDatum(configDatum)

  let loanDatum1 = loanDatum(1000, 15, 1000, 0, 1111111114)
  let loanInDatum = InlineDatum(loanDatum1)
  let loanInValue = t.loanTokenValue()

  let loanDatum2 = loanDatum(1000, 15, 1000, 0, 1111111115)
  let loanOutDatum = InlineDatum(loanDatum2)
  let loanOutValue = t.loanTokenValue()

  let collateralDatum1 = collateralDatum(2000, 12)
  let colInDatum = InlineDatum(collateralDatum1)
  let colInValue = value.merge(t.makeAdaValue(2000), t.loanTokenValue())

  let collateralDatum2 = collateralDatum(500, 12)
  // we need to make sure the amount here is 2x
  let colOutDatum = InlineDatum(collateralDatum2)
  let colOutValue = value.merge(t.makeAdaValue(1000), t.loanTokenValue())

  let oracleInDatum = oracleDatum(2, 11111112, 15, 2)
  let oracleOutDatum = oracleDatum(2, 11111114, 15, 2)
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
