use ccfl/types.{LoanDatum, ScriptHash}

//                   //
// Merkel Loan Vault //
//                   //

type MerkelLoanAction {
  i: Int,
}

// index of withdrawalValidator
// This is a reference to the redeemer case we are validating

validator {
  // this should be in the config datum instead
  fn spend(d: LoanDatum, r: MerkelLoanAction, c: ScriptContext) {
    let ScriptContext { transaction, purpose } = c
    expect Some(configIn) =
      find(
        reference_inputs,
        fn(input) { has(policies(input.output.value), cp) },
      )

    expect InlineDatum(datum) = configIn.output.datum
    expect cDatum: ConfigDatum = datum

    dict.has_key(withdrawals, list.index_of(cDatum.loanRedeemers, r.i))
  }
}

validator(loanVal: ScriptHash) {
  fn loanBalance(r: List<(Int, Int)>, c: ScriptContext) {
    expect ScriptContext { transaction, purpose: WithdrawFrom(stake_cred) } = c

    let Transaction { inputs, outputs, reference_inputs, .. } = transaction

    expect Inline(ScriptCredential(own_validator)) = stake_cred

    expect Some(oracleOut) =
      find(outputs, fn(output) { has(policies(output.value), op) })

    expect InlineDatum(datum) = oracleOut.datum
    expect rDatum: OracleDatum = datum

    let exchangeRate = rDatum.usdAda

    withdraw2(
      fn(input, output) {
        expect InlineDatum(datum) = input.output.datum
        expect d: LoanDatum = datum

        expect Some(loanToken) =
          head(flatten(without_lovelace(input.output.value)))

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

        let adaOut = lovelace_of(colOut.value) / 1000000

        let newCollateralValue = adaOut / exchangeRate

        let minCollateralValue = d.amount * exchangeRate * ( 50 / 100 )

        expect has(policies(output.value), lp)

        expect InlineDatum(datum) = output.datum
        expect datum: LoanDatum = datum

        input.output.address.payment_credential == output.address.payment_credential && datum.amount == d.amount && datum.interest == d.interest && datum.term == d.term && adaOut >= minCollateralValue
      },
      r,
      c,
    )
  }
}
