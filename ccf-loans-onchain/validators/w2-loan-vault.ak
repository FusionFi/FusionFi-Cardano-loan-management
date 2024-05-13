use aiken/bytearray
use aiken/dict
use aiken/list.{find, has, head}
use aiken/transaction.{
  InlineDatum, Input, NoDatum, Output, ScriptContext, Spend, Transaction,
  WithdrawFrom, placeholder,
}
use aiken/transaction/credential.{Inline, Referenced, ScriptCredential}
use aiken/transaction/value.{
  PolicyId, flatten, lovelace_of, policies, without_lovelace,
}
use ccfl/helpers.{withdraw1}
use ccfl/types.{
  CollateralDatum, ConfigDatum, LoanAction, LoanDatum, OracleDatum, SLBalance,
  SLClose, SLLiquidate,
}
use fortuna/utils.{resolve_output_reference}
use tests/tools as t
use tests/transactions.{
  collateralDatum, configDatum, loanActionBalance, loanDatum, oracleDatum,
}

//                     //
// Withdraw Loan Vault //
//                     //

// Loan Vault holds the loan information at a token utxo

validator(op: PolicyId, lp: PolicyId, cp: PolicyId) {
  // this need to take a list of inputs & outputs, and extract the appropriate redeemer
  // Redeemer = [InputIndex, OutputIndex, RedeemerIndex]
  fn withdraw(r: List<(Int, Int, Int)>, c: ScriptContext) {
    expect ScriptContext { transaction, purpose: WithdrawFrom(stake_cred) } = c

    let Transaction { inputs, outputs, reference_inputs, .. } = transaction

    expect Inline(ScriptCredential(own_validator)) = stake_cred

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

    withdraw1(
      fn(in_utxo, out_utxo, rdmr) {
        when rdmr is {
          SLBalance -> {
            expect Some(ownIn) =
              find(
                inputs,
                fn(input) {
                  input.output.address.payment_credential == ScriptCredential(
                    own_validator,
                  )
                },
              )
            expect InlineDatum(datum) = ownIn.output.datum
            expect d: LoanDatum = datum

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

            expect Some(ownOut) =
              find(
                outputs,
                fn(out) {
                  out.address.payment_credential == ScriptCredential(
                    own_validator,
                  )
                },
              )

            let adaOut = lovelace_of(colOut.value) / 1000000

            let newCollateralValue = adaOut / exchangeRate

            let minCollateralValue = d.amount * exchangeRate * ( 50 / 100 )

            expect has(policies(ownOut.value), lp)

            expect InlineDatum(datum) = ownOut.datum
            expect datum: LoanDatum = datum

            datum.amount == d.amount && datum.interest == d.interest && datum.term == d.term && adaOut >= minCollateralValue
          }

          SLLiquidate -> {
            // Liquidate Loan

            expect Some(ownIn) =
              find(
                inputs,
                fn(input) {
                  input.output.address.payment_credential == ScriptCredential(
                    own_validator,
                  )
                },
              )

            expect InlineDatum(datum) = ownIn.output.datum
            expect d: LoanDatum = datum

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

            expect Some(ownOut) =
              find(
                outputs,
                fn(out) {
                  out.address.payment_credential == ScriptCredential(
                    own_validator,
                  )
                },
              )

            let adaOut = lovelace_of(colOut.value) / 1000000

            expect has(policies(ownOut.value), lp)

            expect InlineDatum(datum) = ownOut.datum
            expect datum: LoanDatum = datum

            let minCollateralValue = datum.amount * exchangeRate * ( 85 / 100 )

            datum.amount == d.amount && datum.interest == d.interest && datum.term == d.term && adaOut >= minCollateralValue
          }
          // close
          SLClose -> {
            expect Some(ownIn) =
              find(
                inputs,
                fn(input) {
                  input.output.address.payment_credential == ScriptCredential(
                    own_validator,
                  )
                },
              )

            expect InlineDatum(datum) = ownIn.output.datum
            expect d: LoanDatum = datum
            d.amount == 0
          }
        }
      },
      r,
      c,
    )
  }

  fn loanVal(d: LoanDatum, r: LoanAction, c: ScriptContext) {
    let ScriptContext { transaction, purpose } = c
    expect Spend(oref) = purpose

    let Transaction { inputs, outputs, withdrawals, .. } = c.transaction

    let Output { address: own_addr, .. } =
      resolve_output_reference(inputs, oref)

    let own_withdrawal = Inline(own_addr.payment_credential)

    dict.has_key(withdrawals, own_withdrawal)
  }
}

// Loan Validator Tests
test loan_val() {
  let test_owner = #"face"

  // let test_user = #"cafe"
  let oref1 = t.test_oref(#"face", 1)
  let oref2 = t.test_oref(#"face", 2)
  let oref3 = t.test_oref(#"face", 3)
  let oref4 = t.test_oref(#"face", 4)
  let cref1 = t.test_oref(#"cafe", 2)
  let cref2 = t.test_oref(#"cafe", 3)
  let rref = t.test_oref(#"dead", 6)
  let uref1 = t.test_oref(#"beef", 4)
  let uref2 = t.test_oref(#"beef", 5)
  let uref3 = t.test_oref(#"beef", 1)
  let uref4 = t.test_oref(#"beef", 2)
  let href1 = t.test_oref(#"feed", 3)
  let href2 = t.test_oref(#"feed", 2)
  let href3 = t.test_oref(#"feed", 1)
  let href4 = t.test_oref(#"feed", 4)

  let loanAction = loanActionBalance()

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

  let collateralDatum2 = collateralDatum(1000, 12)
  let colOutDatum = InlineDatum(collateralDatum2)
  let colOutValue = value.merge(t.makeAdaValue(1000), t.loanTokenValue())

  let oracleInDatum = oracleDatum(2, 11111112, 15, 2)
  let oracleOutDatum = oracleDatum(2, 11111114, 15, 2)
  let oInDatum = InlineDatum(oracleInDatum)
  let oOutDatum = InlineDatum(oracleOutDatum)

  let noDatum = NoDatum

  let withdraw0 =
    dict.from_ascending_list(
      [(t.create_stake_credential(t.withLoanHash), 0)],
      t.stakeCompare,
    )

  let r1 = loanAction
  let r2 = loanAction
  let r3 = loanAction
  let r4 = loanAction

  let redeemerList =
    [(3, 1, 0), (6, 3, 1), (9, 5, 2), (12, 7, 3)]

  let list: List<(ScriptPurpose, _)> =
    [
      (Spend(oref1), r1),
      (Spend(oref2), r2),
      (Spend(oref3), r3),
      (Spend(oref4), r4),
      (t.withPurpose(t.with2Hash), redeemerList),
    ]
  let redeemers = dict.from_list(list, bytearray.compare)

  let loanIn1 =
    t.test_input(
      oref1,
      t.test_output(
        t.test_script_address(t.withLoanHash),
        loanInValue,
        loanInDatum,
      ),
    )

  let loanIn2 =
    t.test_input(
      oref2,
      t.test_output(
        t.test_script_address(t.withLoanHash),
        loanInValue,
        loanInDatum,
      ),
    )

  let loanIn3 =
    t.test_input(
      oref3,
      t.test_output(
        t.test_script_address(t.withLoanHash),
        loanInValue,
        loanInDatum,
      ),
    )

  let loanIn4 =
    t.test_input(
      oref4,
      t.test_output(
        t.test_script_address(t.withLoanHash),
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
  let colIn4 =
    t.test_input(
      href4,
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

  let userIn2 =
    t.test_input(
      uref2,
      t.test_output(t.test_address(#"cafe"), t.makeAdaValue(2010), noDatum),
    )

  let userIn3 =
    t.test_input(
      uref3,
      t.test_output(t.test_address(#"cafe"), t.makeAdaValue(2010), noDatum),
    )

  let userIn4 =
    t.test_input(
      uref4,
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
      t.test_script_address(t.withLoanHash),
      loanOutValue,
      loanOutDatum,
    )

  let loanOut2 =
    t.test_output(
      t.test_script_address(t.withLoanHash),
      loanOutValue,
      loanOutDatum,
    )

  let loanOut3 =
    t.test_output(
      t.test_script_address(t.withLoanHash),
      loanOutValue,
      loanOutDatum,
    )

  let loanOut4 =
    t.test_output(
      t.test_script_address(t.withLoanHash),
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

  let colOut4 =
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
        oracleIn,
        userIn1,
        colIn1,
        loanIn1,
        userIn2,
        colIn2,
        loanIn2,
        userIn3,
        colIn3,
        loanIn3,
        userIn4,
        colIn4,
        loanIn4,
      ],
      outputs: [
        oracleOut,
        loanOut1,
        colOut1,
        loanOut2,
        colOut2,
        loanOut3,
        colOut3,
        loanOut4,
        colOut4,
      ],
      redeemers: redeemers,
      withdrawals: withdraw0,
    }

  let ctx1 = ScriptContext { purpose: Spend(oref1), transaction: tx }
  let ctx2 = ScriptContext { purpose: Spend(oref2), transaction: tx }
  let ctx3 = ScriptContext { purpose: Spend(oref3), transaction: tx }
  let ctx4 = ScriptContext { purpose: Spend(oref4), transaction: tx }
  let ctx5 =
    ScriptContext { purpose: withPurpose(t.with2Hash), transaction: tx }

  loanVal(
    t.oracleMintHash,
    t.loanMintHash,
    t.configMintHash,
    loanDatum1,
    r1,
    ctx1,
  )? && loanVal(
    t.oracleMintHash,
    t.loanMintHash,
    t.configMintHash,
    loanDatum1,
    r2,
    ctx2,
  )? && loanVal(
    t.oracleMintHash,
    t.loanMintHash,
    t.configMintHash,
    loanDatum1,
    r3,
    ctx3,
  )? && loanVal(
    t.oracleMintHash,
    t.loanMintHash,
    t.configMintHash,
    loanDatum1,
    r4,
    ctx4,
  )?
}
