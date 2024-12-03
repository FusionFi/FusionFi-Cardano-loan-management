use aiken/collection/dict
use aiken/collection/list
use cardano/address.{Credential, Script}
use cardano/assets.{PolicyId}
use cardano/transaction.{InlineDatum, Output, Transaction}
use ccfl/helpers.{merkelBurn}
use ccfl/types.{CollateralDatum, LoanDatum, WithdrawRedeemer}

//                        //
// Merkel Close Validator //
//                        //

validator close(lp: PolicyId, op: PolicyId) {
  withdraw(r: WithdrawRedeemer, cred: Credential, tx: Transaction) {
    let Transaction { inputs, outputs, mint, .. } = tx

    expect Script(_own_validator) = cred

    expect Some(_oracleOut) =
      list.find(
        outputs,
        fn(output) { list.has(assets.policies(output.value), op) },
      )

    merkelBurn(
      fn(loan, collateral) {
        expect InlineDatum(datum) = loan.datum
        expect ld: LoanDatum = datum
        expect InlineDatum(datum) = collateral.datum
        expect cd: CollateralDatum = datum
        let loanTokenValue = assets.without_lovelace(loan.value)
        let colTokenValue = assets.without_lovelace(collateral.value)

        expect [Pair(loanTn, 1)] =
          loanTokenValue
            |> assets.tokens(lp)
            |> dict.to_pairs()

        expect Some(burnVal) =
          assets.zero
            |> assets.add(lp, loanTn, -2)
            |> assets.flatten()
            |> list.head()

        let burns = assets.flatten(mint)

        list.has(burns, burnVal) && ld.amount == 0 && cd.amount == 0 && loanTokenValue == colTokenValue && cd.yield == 0
      },
      r.a,
      inputs,
    )
  }

  else(_) {
    fail
  }
}
