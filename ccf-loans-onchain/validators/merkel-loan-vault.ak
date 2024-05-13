use aiken/dict
use aiken/list
use aiken/transaction.{InlineDatum, ScriptContext, Transaction, WithdrawFrom}
use aiken/transaction/credential.{Inline, ScriptCredential}
use aiken/transaction/value.{PolicyId}
use ccfl/helpers.{withBurn, withdraw2}
use ccfl/types.{
  CollateralDatum, ConfigDatum, LoanDatum, MerkelConfigDatum, MerkelLoanAction,
  OracleDatum, ScriptHash,
}
use tests/tools as t

//                   //
// Merkel Loan Vault //
//                   //

validator(cp: PolicyId) {
  // this should be in the config datum instead
  fn spend(d: LoanDatum, r: MerkelLoanAction, c: ScriptContext) {
    let ScriptContext { transaction, purpose } = c
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

    let Transaction { inputs, outputs, reference_inputs, .. } = transaction

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

    withdraw2(
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

        let newCollateralValue = adaOut / exchangeRate

        let minCollateralValue = d.amount * exchangeRate * ( 50 / 100 )

        expect list.has(value.policies(output.value), lp)

        expect InlineDatum(datum) = output.datum
        expect datum: LoanDatum = datum

        input.address.payment_credential == output.address.payment_credential && datum.amount == d.amount && datum.interest == d.interest && datum.term == d.term && adaOut >= minCollateralValue
      },
      r,
      c,
    )
  }
}

validator(loanVal: ScriptHash, lp: PolicyId, op: PolicyId, cp: PolicyId) {
  fn loanLiquidate(r: List<(Int, Int)>, c: ScriptContext) {
    expect ScriptContext { transaction, purpose: WithdrawFrom(stake_cred) } = c

    let Transaction { inputs, outputs, reference_inputs, .. } = transaction

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

    withdraw2(
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
      r,
      c,
    )
  }
}

validator(loanHash: ScriptHash, lp: PolicyId, op: PolicyId) {
  fn loanClose(r: List<Int>, c: ScriptContext) {
    expect ScriptContext { transaction, purpose: WithdrawFrom(stake_cred) } = c

    let Transaction { inputs, outputs, reference_inputs, mint, .. } =
      transaction

    expect Inline(ScriptCredential(own_validator)) = stake_cred

    expect Some(oracleOut) =
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
      r,
      c,
    )
  }
}
//                 //
// Validator Tests //
//                 //

// test loan_val_balance() {
//   let test_owner = #"face"

//   // let test_user = #"cafe"
//   let oref = t.test_oref(#"face", 1)
//   let cref = t.test_oref(#"cafe", 2)
//   let rref = t.test_oref(#"dead", 6)
//   let uref = t.test_oref(#"beef", 4)
//   let href = t.test_oref(#"feed", 3)

//   let loanAction = loanActionBalance()

//   // let loanMintedValue =
//   //   value.to_minted_value(value.merge(t.loanTokenValue(), t.loanTokenValue()))
//   let configDatum =
//     configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
//   let configInDatum = InlineDatum(configDatum)

//   let loanDatum1 = loanDatum(1000, 15, 1000, 0, 1111111114)
//   let loanInDatum = InlineDatum(loanDatum1)
//   let loanInValue = t.loanTokenValue()

//   let loanDatum2 = loanDatum(1000, 15, 1000, 0, 1111111115)
//   let loanOutDatum = InlineDatum(loanDatum2)
//   let loanOutValue = t.loanTokenValue()

//   let collateralDatum1 = collateralDatum(2000, 12)
//   let colInDatum = InlineDatum(collateralDatum1)
//   let colInValue = value.merge(t.makeAdaValue(2000), t.loanTokenValue())

//   let collateralDatum2 = collateralDatum(1000, 12)
//   let colOutDatum = InlineDatum(collateralDatum2)
//   let colOutValue = value.merge(t.makeAdaValue(1000), t.loanTokenValue())

//   let oracleInDatum = oracleDatum(2, 11111112, 15, 2)
//   let oracleOutDatum = oracleDatum(2, 11111114, 15, 2)
//   let oInDatum = InlineDatum(oracleInDatum)
//   let oOutDatum = InlineDatum(oracleOutDatum)

//   let noDatum = NoDatum

//   let loanIn =
//     t.test_input(
//       oref,
//       t.test_output(
//         t.test_script_address(t.loanValHash),
//         loanInValue,
//         loanInDatum,
//       ),
//     )

//   let colIn =
//     t.test_input(
//       href,
//       t.test_output(
//         t.test_script_address(t.collateralValHash),
//         colInValue,
//         colInDatum,
//       ),
//     )

//   let userIn =
//     t.test_input(
//       uref,
//       t.test_output(t.test_address(#"cafe"), t.makeAdaValue(2010), noDatum),
//     )

//   let configIn =
//     t.test_input(
//       cref,
//       t.test_output(
//         t.test_script_address(t.configValHash),
//         t.configValue(),
//         configInDatum,
//       ),
//     )

//   let oracleIn =
//     t.test_input(
//       rref,
//       t.test_output(
//         t.test_script_address(t.oracleValHash),
//         t.oracleValue(),
//         oInDatum,
//       ),
//     )

//   let oracleOut =
//     t.test_output(
//       t.test_script_address(t.oracleValHash),
//       t.oracleValue(),
//       oOutDatum,
//     )

//   let loanOut =
//     t.test_output(
//       t.test_script_address(t.loanValHash),
//       loanOutValue,
//       loanOutDatum,
//     )

//   let colOut =
//     t.test_output(
//       t.test_script_address(t.collateralValHash),
//       colOutValue,
//       colOutDatum,
//     )

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       extra_signatories: [test_owner],
//       inputs: [oracleIn, userIn, colIn, loanIn],
//       outputs: [loanOut, colOut, oracleOut],
//     }

//   let ctx1 = ScriptContext { purpose: Spend(oref), transaction: tx }

//   loanVal(
//     t.oracleMintHash,
//     t.loanMintHash,
//     t.configMintHash,
//     loanDatum1,
//     loanAction,
//     ctx1,
//   )?
// }
