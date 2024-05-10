use aiken/dict.{to_list}
use aiken/list
use aiken/transaction.{
  InlineDatum, Mint, NoDatum, ScriptContext, Transaction, placeholder,
}
use aiken/transaction/credential
use aiken/transaction/value.{from_minted_value, tokens}
use ccfl/types.{OBurn, OMint, OracleMintAction, VerificationKeyHash}
use tests/tools as t
use tests/transactions.{collateralDatum, oracleDatum, oracleMintActionMint}

//             //
// Oracle Mint //
//             //

validator(o: VerificationKeyHash) {
  fn oracleMint(r: OracleMintAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Mint(policyId) = purpose

    expect [(oName, oAmt)] =
      transaction.mint
        |> from_minted_value()
        |> tokens(policyId)
        |> to_list()

    when r is {
      // checks signed by owner and No. of tokens
      OMint -> list.has(transaction.extra_signatories, o) && oAmt == 1
      OBurn -> list.has(transaction.extra_signatories, o) && oAmt == -1
    }
  }
}

//       //
// Tests //
//       //

test oracle_mint() {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)

  let oracleDatum1 = oracleDatum(1, 11111111, 15, 2)
  let outDatum = InlineDatum(oracleDatum1)

  let ownerInput =
    t.test_input(
      oref,
      t.test_output(t.test_address(test_owner), t.makeAdaValue(10), NoDatum),
    )

  let oracleOutput =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      t.oracleValue(),
      outDatum,
    )

  let tx =
    Transaction {
      ..placeholder(),
      mint: t.oracleMintedValue(),
      extra_signatories: [test_owner],
      inputs: [ownerInput],
      outputs: [oracleOutput],
    }

  let ctx = ScriptContext { purpose: Mint(t.oracleMintHash), transaction: tx }

  oracleMint(test_owner, oracleMintActionMint(), ctx)?
}

test oracle_mint_qty_fail() fail {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)

  let oracleDatum1 = oracleDatum(1, 11111111, 15, 2)
  let outDatum = InlineDatum(oracleDatum1)

  let mintValue =
    value.to_minted_value(
      value.merge(t.oracleTokenValue(), t.oracleTokenValue()),
    )

  let ownerInput =
    t.test_input(
      oref,
      t.test_output(t.test_address(test_owner), t.makeAdaValue(10), NoDatum),
    )

  let oracleOutput =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      t.oracleValue(),
      outDatum,
    )

  let tx =
    Transaction {
      ..placeholder(),
      mint: mintValue,
      extra_signatories: [test_owner],
      inputs: [ownerInput],
      outputs: [oracleOutput],
    }

  let ctx = ScriptContext { purpose: Mint(t.oracleMintHash), transaction: tx }

  oracleMint(test_owner, oracleMintActionMint(), ctx)?
}

test oracle_mint_datum_fail() fail {
  // This passes because we dont guarantee output datum
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)

  let oracleDatum1 = collateralDatum(1, 11111111)
  let outDatum = InlineDatum(oracleDatum1)

  let ownerInput =
    t.test_input(
      oref,
      t.test_output(t.test_address(test_owner), t.makeAdaValue(10), NoDatum),
    )

  let oracleOutput =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      t.oracleValue(),
      outDatum,
    )

  let tx =
    Transaction {
      ..placeholder(),
      mint: t.oracleMintedValue(),
      extra_signatories: [test_owner],
      inputs: [ownerInput],
      outputs: [oracleOutput],
    }

  let ctx = ScriptContext { purpose: Mint(t.oracleMintHash), transaction: tx }

  oracleMint(test_owner, oracleMintActionMint(), ctx)?
}

test oracle_mint_sig_fail() fail {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)

  let oracleDatum1 = oracleDatum(1, 11111111, 15, 2)
  let outDatum = InlineDatum(oracleDatum1)

  let ownerInput =
    t.test_input(
      oref,
      t.test_output(t.test_address(test_owner), t.makeAdaValue(10), NoDatum),
    )

  let oracleOutput =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      t.oracleValue(),
      outDatum,
    )

  let tx =
    Transaction {
      ..placeholder(),
      mint: t.oracleMintedValue(),
      extra_signatories: [#"cafe"],
      inputs: [ownerInput],
      outputs: [oracleOutput],
    }

  let ctx = ScriptContext { purpose: Mint(t.oracleMintHash), transaction: tx }

  oracleMint(test_owner, oracleMintActionMint(), ctx)?
}
