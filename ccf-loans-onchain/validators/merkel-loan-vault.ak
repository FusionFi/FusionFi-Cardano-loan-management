use ccfl/helpers.{withdraw2, withBurn}
use ccfl/types.{LoanDatum, ScriptHash, MerkelLoanAction, OraclDatum, ConfigDatum, CollateralDatum}
use aiken/list
use aiken/dict 
use aiken/transaction.{ScriptContext, InlineDatum, Transaction, WithdrawFrom, }
use aiken/transaction/credential.{ScriptCredential, Inline}
use aiken/transaction/value.{PolicyId}

//                   //
// Merkel Loan Vault //
//                   //

validator(cp: PolicyId) {
  // this should be in the config datum instead
  fn spend(d: LoanDatum, r: MerkelLoanAction, c: ScriptContext) {
    let ScriptContext { transaction, purpose } = c
    expect Some(configIn) =
      list.find(
        reference_inputs,
        fn(input) { list.has(value.policies(input.output.value), cp) },
      )

    expect InlineDatum(datum) = configIn.output.datum
    expect cDatum: ConfigDatum = datum

    dict.has_key(withdrawals, list.index_of(cDatum.loanRedeemers, r.i))
  }
}

validator(loanVal: ScriptHash, lp: PolicyId, op: PolicyId) {
  fn loanBalance(r: List<(Int, Int)>, c: ScriptContext) {
    expect ScriptContext { transaction, purpose: WithdrawFrom(stake_cred) } = c

    let Transaction { inputs, outputs, reference_inputs, .. } = transaction

    expect Inline(ScriptCredential(own_validator)) = stake_cred

    expect Some(oracleOut) =
      list.find(outputs, fn(output) { list.has(value.policies(output.value), op) })

    expect InlineDatum(datum) = oracleOut.datum
    expect rDatum: OracleDatum = datum

    let exchangeRate = rDatum.usdAda

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
        expect cDatum: CollateralDatum = datum

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

validator(loanVal: ScriptHash) {
  fn loanLiquidate(r: List<(Int, Int)>, c: ScriptContext) {
    expect ScriptContext { transaction, purpose: WithdrawFrom(stake_cred) } = c

    let Transaction { inputs, outputs, reference_inputs, .. } = transaction

    expect Inline(ScriptCredential(own_validator)) = stake_cred

    expect Some(oracleOut) =
      list.find(outputs, fn(output) { list.has(value.policies(output.value), op) })

    expect InlineDatum(datum) = oracleOut.datum
    expect rDatum: OracleDatum = datum

    let exchangeRate = rDatum.usdAda

    withdraw2(
      fn(input, output) { // input here is already an input.output
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
        expect cDatum: CollateralDatum = datum

        let adaOut = value.lovelace_of(colOut.value) / 1000000

        expect list.has(value.policies(output.value), lp)

        expect InlineDatum(datum) = output.datum
        expect datum: LoanDatum = datum

        let minCollateralValue = datum.amount * exchangeRate * ( 85 / 100 )

        input.address.payment_credential == output.address.payment_credential && datum.amount == d.amount && datum.interest == d.interest && datum.term == d.term && adaOut >= minCollateralValue
      }
      r,
      c,
    )
  }
}

validator(loanHash: ScriptHash) {
  fn loanClose(r: List<Int>, c: ScriptContext) {
    expect ScriptContext { transaction, purpose: WithdrawFrom(stake_cred) } = c

    let Transaction { inputs, outputs, reference_inputs, mint .. } = transaction

    expect Inline(ScriptCredential(own_validator)) = stake_cred

    expect Some(oracleOut) =
      list.find(outputs, fn(output) { has(policies(output.value), op) })

    withBurn(
      fn(input) {
        expect InlineDatum(datum) = input.datum
        expect d: LoanDatum = datum

        let loanTokenVal =
          without_lovelace(input.value)
        
        expect [(loanTn, 1)] = 
          loanTokenVal
            |> value.tokens(lp)
            |> dict.to_list()
        
        let burnVal =
          value.zero()
            |> value.add(lp, loanTn, -2)
            |> value.flatten()

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