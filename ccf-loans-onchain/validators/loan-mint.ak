use aiken/dict
use aiken/list.{filter, find, has, head}
use aiken/transaction.{
  InlineDatum, Input, Mint, NoDatum, Output, ScriptContext, Transaction,
  placeholder,
}
use aiken/transaction/credential.{ScriptCredential}
use aiken/transaction/value.{PolicyId, lovelace_of, policies}
use ccfl/types.{
  ABurn, AMint, CollateralDatum, LoanDatum, LoanMintAction, MerkelConfigDatum,
  OracleDatum,
}
use tests/tools as t
use tests/transactions.{
  collateralDatum, configDatumIn, loanDatum, loanMintActionMint, oracleDatum,
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

    expect [Pair(_tName, tAmt)] =
      mint
        |> value.from_minted_value()
        |> value.tokens(policyId)
        |> dict.to_pairs()

    when r is {
      AMint { amount, rewards, term, timestamp } -> {
        // checks for Oracle ref in
        expect Some(oracleOut) =
          find(outputs, fn(output) { has(policies(output.value), op) })
        expect [Pair(oracleTn, 1)] =
          oracleOut.value
            |> value.tokens(op)
            |> dict.to_pairs()
        // checks oracle datum
        expect InlineDatum(datum) = oracleOut.datum
        expect rDatum: OracleDatum = datum
        // pulls exchange rate
        let exchangeRate = rDatum.exchange
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
        expect cDatum: MerkelConfigDatum = datum

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
        let decimalComp = lDatum.amount * 1000
        let exchangeValue = decimalComp / exchangeRate
        // checks loan values against redeemer && collateral && 2 tokens minted
        lDatum.amount == amount && lDatum.term == term && colDatum.amount == amount * 2 && lovelace_of(
          colOut.value,
        ) >= exchangeValue * 1000000 && tAmt == 2 && lDatum.oracle == oracleTn && lDatum.rewards == rewards && lDatum.timestamp == timestamp && colDatum.yield == 0
      }
      // True
      // always allows Burn -> This needs to be changed to only allow burning when the loan is 
      // closed or there is no more loan value (ie liquidated)
      ABurn -> True
    }
  }
}

//                 //
// Loan Mint Tests //
//                 //

test loan_mint() {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)
  let cref = t.test_oref(#"cafe", 2)
  let rref = t.test_oref(#"dead", 6)

  let mintAction = loanMintActionMint(1000, 12, 1111111114)

  let loanMintedValue =
    value.to_minted_value(value.merge(t.loanTokenValue(), t.loanTokenValue()))

  let configInDatum = configDatumIn()

  let loanDatum = loanDatum(1000, 0, 12, 1111111114, #"beef")
  let loanOutDatum = InlineDatum(loanDatum)
  let loanOutValue = t.loanTokenValue()

  let collateralDatum = collateralDatum(2000, 12, 0)
  let colOutDatum = InlineDatum(collateralDatum)
  let colOutValue = value.merge(t.makeAdaValue(2002), t.loanTokenValue())

  let oracleInDatum = oracleDatum(2000, 11111112, 1000000, 200000, "USD")
  let oracleOutDatum = oracleDatum(1000, 11111114, 1000000, 200000, "USD")
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
      t.test_script_address(t.merkelLoanSpend),
      loanOutValue,
      loanOutDatum,
    )

  let colOut =
    t.test_output(
      t.test_script_address(t.merkelCollateralSpend),
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

test mint_loanDatumFail() fail {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)
  let cref = t.test_oref(#"cafe", 2)
  let rref = t.test_oref(#"dead", 6)

  let mintAction = loanMintActionMint(1000, 12, 1111111114)

  let loanMintedValue =
    value.to_minted_value(value.merge(t.loanTokenValue(), t.loanTokenValue()))

  let configInDatum = configDatumIn()

  let loanDatum = loanDatum(500, 0, 12, 1111111114, #"beef")
  let loanOutDatum = InlineDatum(loanDatum)
  let loanOutValue = t.loanTokenValue()

  let collateralDatum = collateralDatum(2000, 12, 0)
  let colOutDatum = InlineDatum(collateralDatum)
  let colOutValue = value.merge(t.makeAdaValue(2002), t.loanTokenValue())

  let oracleInDatum = oracleDatum(2000, 11111112, 1000000, 200000, "USD")
  let oracleOutDatum = oracleDatum(1000, 11111114, 1000000, 200000, "USD")
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
      t.test_script_address(t.merkelLoanSpend),
      loanOutValue,
      loanOutDatum,
    )

  let colOut =
    t.test_output(
      t.test_script_address(t.merkelCollateralSpend),
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

  loanMint(t.oracleMintHash, t.configMintHash, mintAction, ctx)
}

test mint_colDatumFail() fail {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)
  let cref = t.test_oref(#"cafe", 2)
  let rref = t.test_oref(#"dead", 6)

  let mintAction = loanMintActionMint(1000, 12, 1111111114)

  let loanMintedValue =
    value.to_minted_value(value.merge(t.loanTokenValue(), t.loanTokenValue()))

  let configInDatum = configDatumIn()

  let loanDatum = loanDatum(1000, 0, 12, 1111111114, #"beef")
  let loanOutDatum = InlineDatum(loanDatum)
  let loanOutValue = t.loanTokenValue()

  let collateralDatum = collateralDatum(1000, 12, 0)
  let colOutDatum = InlineDatum(collateralDatum)
  let colOutValue = value.merge(t.makeAdaValue(2002), t.loanTokenValue())

  let oracleInDatum = oracleDatum(2000, 11111112, 1000000, 200000, "USD")
  let oracleOutDatum = oracleDatum(1000, 11111114, 1000000, 200000, "USD")
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
      t.test_script_address(t.merkelLoanSpend),
      loanOutValue,
      loanOutDatum,
    )

  let colOut =
    t.test_output(
      t.test_script_address(t.merkelCollateralSpend),
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

  loanMint(t.oracleMintHash, t.configMintHash, mintAction, ctx)
}

test mint_actionFail() fail {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)
  let cref = t.test_oref(#"cafe", 2)
  let rref = t.test_oref(#"dead", 6)

  let mintAction = loanMintActionMint(500, 12, 1111111114)

  let loanMintedValue =
    value.to_minted_value(value.merge(t.loanTokenValue(), t.loanTokenValue()))

  let configInDatum = configDatumIn()

  let loanDatum = loanDatum(1000, 0, 12, 1111111114, #"beef")
  let loanOutDatum = InlineDatum(loanDatum)
  let loanOutValue = t.loanTokenValue()

  let collateralDatum = collateralDatum(2000, 12, 0)
  let colOutDatum = InlineDatum(collateralDatum)
  let colOutValue = value.merge(t.makeAdaValue(2002), t.loanTokenValue())

  let oracleInDatum = oracleDatum(2000, 11111112, 1000000, 200000, "USD")
  let oracleOutDatum = oracleDatum(1000, 11111114, 1000000, 200000, "USD")
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
      t.test_script_address(t.merkelLoanSpend),
      loanOutValue,
      loanOutDatum,
    )

  let colOut =
    t.test_output(
      t.test_script_address(t.merkelCollateralSpend),
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

  loanMint(t.oracleMintHash, t.configMintHash, mintAction, ctx)
}

test mint_oracleFail() fail {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)
  let cref = t.test_oref(#"cafe", 2)
  let rref = t.test_oref(#"dead", 6)

  let mintAction = loanMintActionMint(1000, 12, 1111111114)

  let loanMintedValue =
    value.to_minted_value(value.merge(t.loanTokenValue(), t.loanTokenValue()))

  let configInDatum = configDatumIn()

  let loanDatum = loanDatum(1000, 0, 12, 1111111114, #"beef")
  let loanOutDatum = InlineDatum(loanDatum)
  let loanOutValue = t.loanTokenValue()

  let collateralDatum = collateralDatum(2000, 12, 0)
  let colOutDatum = InlineDatum(collateralDatum)
  let colOutValue = value.merge(t.makeAdaValue(2002), t.loanTokenValue())

  let oracleInDatum = oracleDatum(2000, 11111112, 1000000, 200000, "USD")
  let oracleOutDatum = oracleDatum(1000, 11111114, 1000000, 200000, "USD")
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
      t.configValue(),
      oOutDatum,
    )

  let loanOut =
    t.test_output(
      t.test_script_address(t.merkelLoanSpend),
      loanOutValue,
      loanOutDatum,
    )

  let colOut =
    t.test_output(
      t.test_script_address(t.merkelCollateralSpend),
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

  loanMint(t.oracleMintHash, t.configMintHash, mintAction, ctx)
}

test collateral_ValueFail() {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)
  let cref = t.test_oref(#"cafe", 2)
  let rref = t.test_oref(#"dead", 6)

  let mintAction = loanMintActionMint(1000, 12, 1111111114)

  let loanMintedValue =
    value.to_minted_value(value.merge(t.loanTokenValue(), t.loanTokenValue()))

  let configInDatum = configDatumIn()

  let loanDatum = loanDatum(1000, 0, 12, 1111111114, #"beef")
  let loanOutDatum = InlineDatum(loanDatum)
  let loanOutValue = t.loanTokenValue()

  let collateralDatum = collateralDatum(2000, 12, 0)
  let colOutDatum = InlineDatum(collateralDatum)
  let colOutValue = value.merge(t.makeAdaValue(1002), t.loanTokenValue())

  let oracleInDatum = oracleDatum(2000, 11111112, 1000000, 200000, "USD")
  let oracleOutDatum = oracleDatum(1000, 11111114, 1000000, 200000, "USD")
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
      t.test_script_address(t.merkelLoanSpend),
      loanOutValue,
      loanOutDatum,
    )

  let colOut =
    t.test_output(
      t.test_script_address(t.merkelCollateralSpend),
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
  trace @"VULNERABILITY"
  trace @"We should be checking collateral matches expected collateral"
  loanMint(t.oracleMintHash, t.configMintHash, mintAction, ctx)?
}
