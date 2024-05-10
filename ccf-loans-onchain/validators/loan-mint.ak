use aiken/dict
use aiken/list.{filter, find, has, head}
use aiken/transaction.{
  InlineDatum, Input, Mint, NoDatum, Output, ScriptContext, Transaction,
  placeholder,
}
use aiken/transaction/credential.{ScriptCredential}
use aiken/transaction/value.{PolicyId, lovelace_of, policies}
use ccfl/types.{
  ABurn, AMint, CollateralDatum, ConfigDatum, LoanDatum, LoanMintAction,
  OracleDatum,
}
use tests/tools as t
use tests/transactions.{
  collateralDatum, configDatum, loanDatum, loanMintActionMint, oracleDatum,
}

//                    //
// Separate Loan Mint //
//                    //

// Mints 2 tokens 
// sends one to loan vault with datum
// sends one to collateral vault with datum

validator(op: PolicyId, cp: PolicyId) {
  fn loanMint(r: LoanMintAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Mint(policyId) = purpose

    let Transaction { mint, outputs, reference_inputs, .. } = transaction

    expect [(_tName, tAmt)] =
      mint
        |> value.from_minted_value()
        |> value.tokens(policyId)
        |> dict.to_list()

    when r is {
      AMint { loanCurrency, loanValue, timestamp } -> {
        // checks for Oracle ref in
        expect Some(oracleOut) =
          find(outputs, fn(output) { has(policies(output.value), op) })
        // checks oracle datum
        expect InlineDatum(datum) = oracleOut.datum
        expect rDatum: OracleDatum = datum
        // pulls exchange rate
        let exchangeRate = rDatum.usdAda
        // checks for config input
        expect Some(configIn) =
          head(
            filter(
              reference_inputs,
              fn(ref) { has(policies(ref.output.value), cp) },
            ),
          )
        // checks config datum
        expect InlineDatum(datum) = configIn.output.datum
        expect cDatum: ConfigDatum = datum
        // sends to loan validator in config
        expect Some(loanOut) =
          find(
            outputs,
            fn(output) {
              output.address.payment_credential == ScriptCredential(
                cDatum.loanVal,
              ) && has(policies(output.value), policyId)
            },
          )
        // sends to collateral validator in config
        expect Some(colOut) =
          find(
            outputs,
            fn(output) {
              output.address.payment_credential == ScriptCredential(
                cDatum.colVal,
              ) && has(policies(output.value), policyId)
            },
          )
        // checks loan output datum
        expect InlineDatum(datum) = loanOut.datum
        expect lDatum: LoanDatum = datum
        // checks collateral output datum
        expect InlineDatum(datum) = colOut.datum
        expect colDatum: CollateralDatum = datum
        // checks loan values against redeemer && collateral && 2 tokens minted
        lDatum.amount == loanValue && lDatum.interest == 15 && lDatum.term == 0 && colDatum.amount == loanValue * 2 && lovelace_of(
          colOut.value,
        ) >= lDatum.amount * exchangeRate * 1000000 && tAmt == 2
      }
      // always allows Burn -> This needs to be changed to only allow burning when the loan is 
      // closed or there is no more loan value (ie liquidated)
      ABurn -> True
    }
  }
}

// Loan Mint Tests
test loan_mint() {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)
  let cref = t.test_oref(#"cafe", 2)
  let rref = t.test_oref(#"dead", 6)

  let mintAction = loanMintActionMint("USD", 1000, 1111111113)

  let loanMintedValue =
    value.to_minted_value(value.merge(t.loanTokenValue(), t.loanTokenValue()))

  let configDatum =
    configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
  let configInDatum = InlineDatum(configDatum)

  let loanDatum = loanDatum(1000, 15, 1000, 0, 1111111114)
  let loanOutDatum = InlineDatum(loanDatum)
  let loanOutValue = t.loanTokenValue()

  let collateralDatum = collateralDatum(2000, 12)
  let colOutDatum = InlineDatum(collateralDatum)
  let colOutValue = value.merge(t.makeAdaValue(2000), t.loanTokenValue())

  let oracleInDatum = oracleDatum(2, 11111112, 15, 2)
  let oracleOutDatum = oracleDatum(1, 11111114, 15, 2)
  let oInDatum = InlineDatum(oracleInDatum)
  let oOutDatum = InlineDatum(oracleOutDatum)

  let noDatum = NoDatum

  let userIn =
    t.test_input(
      oref,
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
      mint: loanMintedValue,
      extra_signatories: [test_owner],
      inputs: [userIn, oracleIn],
      outputs: [loanOut, colOut, oracleOut],
    }

  let ctx = ScriptContext { purpose: Mint(t.loanMintHash), transaction: tx }

  loanMint(t.oracleMintHash, t.configMintHash, mintAction, ctx)?
}
