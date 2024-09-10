use aiken/collection/dict
use aiken/collection/list.{filter, find, has, head}
use cardano/address.{Script}
use cardano/assets.{PolicyId, lovelace_of, policies}
use cardano/transaction.{InlineDatum, Input, Output, Transaction}
use ccfl/helpers
use ccfl/types.{
  ABurn, AMint, CollateralDatum, LoanDatum, LoanMintAction, MerkelConfigDatum,
  OracleDatum,
}

//                    //
// Separate Loan Mint //
//                    //

// Mints 2 tokens 
// sends one to loan vault with datum
// sends one to collateral vault with datum

validator loanMint(op: PolicyId, cp: PolicyId) {
  mint(r: LoanMintAction, policyId: PolicyId, tx: Transaction) {
    let Transaction { mint, outputs, reference_inputs, .. } = tx

    // checks for config input
    let cDatum: MerkelConfigDatum =
      helpers.get_config_datum(tx.reference_inputs, cp)

    expect [Pair(tName, tAmt)] =
      mint
        |> assets.tokens(policyId)
        |> dict.to_pairs()

    when r is {
      AMint { amount, rewards, term, timestamp } -> {
        // checks for Oracle ref in
        expect Some(oracleOut) =
          find(outputs, fn(output) { has(policies(output.value), op) })

        expect [Pair(oracleTn, 1)] =
          oracleOut.value
            |> assets.tokens(op)
            |> dict.to_pairs()

        // checks oracle datum
        expect InlineDatum(datum) = oracleOut.datum
        expect rDatum: OracleDatum = datum

        // pulls exchange rate
        let exchangeRate = rDatum.exchange

        // sends to loan validator in config
        expect Some(loanOut) =
          find(
            outputs,
            fn(output) {
              output.address.payment_credential == Script(cDatum.loanVal) && has(
                policies(output.value),
                policyId,
              )
            },
          )

        // sends to collateral validator in config
        expect Some(colOut) =
          find(
            outputs,
            fn(output) {
              output.address.payment_credential == Script(cDatum.colVal) && has(
                policies(output.value),
                policyId,
              )
            },
          )

        // checks loan output datum
        expect InlineDatum(datum) = loanOut.datum
        expect lDatum: LoanDatum = datum

        // checks collateral output datum
        expect InlineDatum(datum) = colOut.datum
        expect colDatum: CollateralDatum = datum

        let decimalComp = lDatum.amount * 1000
        let exchangeValue = decimalComp / exchangeRate

        // checks loan values against redeemer && collateral && 2 tokens minted
        and {
          lDatum.amount == amount,
          lDatum.term == term,
          colDatum.amount == amount * 2,
          lovelace_of(colOut.value) >= exchangeValue * 1000000,
          tAmt == 2,
          lDatum.oracle == oracleTn,
          lDatum.rewards == rewards,
          lDatum.timestamp == timestamp,
          colDatum.yield == 0,
        }
      }
      // True
      // always allows Burn -> This needs to be changed to only allow burning when the loan is 
      // closed or there is no more loan value (ie liquidated)
      ABurn -> {
        let Pair(lin, cin) =
          helpers.get_loan_col_in_datum(
            tx.inputs,
            assets.from_asset(policyId, tName, 1),
            cDatum.loanVal,
            cDatum.colVal,
          )

        expect 0 = cin.amount
        expect 0 = lin.amount

        tAmt == -2
      }
    }
  }

  else(_) {
    fail
  }
}
