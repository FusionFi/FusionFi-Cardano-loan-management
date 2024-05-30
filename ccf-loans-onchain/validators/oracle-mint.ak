use aiken/dict.{to_list}
use aiken/list
use aiken/transaction.{
  InlineDatum, Mint, NoDatum, ScriptContext, Transaction, placeholder,
}
use aiken/transaction/credential.{ScriptCredential}
use aiken/transaction/value.{PolicyId, from_minted_value, tokens}
use ccfl/types.{
  MerkelConfigDatum, OBurn, OMint, OracleDatum, OracleMintAction,
  VerificationKeyHash,
}
use tests/tools as t
use tests/transactions.{
  collateralDatum, configInput, oracleDatum, oracleMintActionMint,
}

//             //
// Oracle Mint //
//             //

validator(o: VerificationKeyHash, cp: PolicyId) {
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
      // TODO: verify output datum
      OMint -> {
        expect Some(configIn) =
          list.find(
            transaction.reference_inputs,
            fn(input) { list.has(value.policies(input.output.value), cp) },
          )

        expect InlineDatum(datum) = configIn.output.datum
        expect cDatum: MerkelConfigDatum = datum

        expect Some(out) =
          list.find(
            transaction.outputs,
            fn(output) {
              expect [(oName, oAmt)] =
                output.value
                  |> value.without_lovelace()
                  |> value.tokens(policyId)
                  |> dict.to_list()
              output.address.payment_credential == ScriptCredential(
                cDatum.oracleVal,
              )
            },
          )

        list.has(transaction.extra_signatories, o) && oAmt == 1
      }
      OBurn -> list.has(transaction.extra_signatories, o) && oAmt == -1
    }
  }
}
//       //
// Tests //
//       //

// test oracle_mint() {
//   let test_owner = #"face"

//   let oref = t.test_oref(#"face", 1)

//   let oracleDatum1 = oracleDatum(1, 11111111, 15, 2)
//   let outDatum = InlineDatum(oracleDatum1)
//   let configIn = configInput()

//   let ownerInput =
//     t.test_input(
//       oref,
//       t.test_output(t.test_address(test_owner), t.makeAdaValue(10), NoDatum),
//     )

//   let oracleOutput =
//     t.test_output(
//       t.test_script_address(t.oracleValHash),
//       t.oracleValue(),
//       outDatum,
//     )

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       mint: t.oracleMintedValue(),
//       extra_signatories: [test_owner],
//       inputs: [ownerInput],
//       outputs: [oracleOutput],
//     }

//   let ctx = ScriptContext { purpose: Mint(t.oracleMintHash), transaction: tx }

//   oracleMint(test_owner, t.configMintHash, oracleMintActionMint(), ctx)?
// }

// test oracle_mint_qty_fail() fail {
//   let test_owner = #"face"

//   let oref = t.test_oref(#"face", 1)

//   let oracleDatum1 = oracleDatum(1, 11111111, 15, 2)
//   let outDatum = InlineDatum(oracleDatum1)

//   let configIn = configInput()

//   let mintValue =
//     value.to_minted_value(
//       value.merge(t.oracleTokenValue(), t.oracleTokenValue()),
//     )

//   let ownerInput =
//     t.test_input(
//       oref,
//       t.test_output(t.test_address(test_owner), t.makeAdaValue(10), NoDatum),
//     )

//   let oracleOutput =
//     t.test_output(
//       t.test_script_address(t.oracleValHash),
//       t.oracleValue(),
//       outDatum,
//     )

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       mint: mintValue,
//       extra_signatories: [test_owner],
//       inputs: [ownerInput],
//       outputs: [oracleOutput],
//     }

//   let ctx = ScriptContext { purpose: Mint(t.oracleMintHash), transaction: tx }

//   oracleMint(test_owner, t.configMintHash, oracleMintActionMint(), ctx)?
// }

// test oracle_mint_datum_fail() fail {
//   // This passes because we dont guarantee output datum
//   let test_owner = #"face"

//   let oref = t.test_oref(#"face", 1)

//   let oracleDatum1 = collateralDatum(1, 11111111)
//   let outDatum = InlineDatum(oracleDatum1)

//   let configIn = configInput()

//   let ownerInput =
//     t.test_input(
//       oref,
//       t.test_output(t.test_address(test_owner), t.makeAdaValue(10), NoDatum),
//     )

//   let oracleOutput =
//     t.test_output(
//       t.test_script_address(t.oracleValHash),
//       t.oracleValue(),
//       outDatum,
//     )

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       mint: t.oracleMintedValue(),
//       extra_signatories: [test_owner],
//       inputs: [ownerInput],
//       outputs: [oracleOutput],
//     }

//   let ctx = ScriptContext { purpose: Mint(t.oracleMintHash), transaction: tx }

//   oracleMint(test_owner, t.configMintHash, oracleMintActionMint(), ctx)?
// }

// test oracle_mint_sig_fail() fail {
//   let test_owner = #"face"

//   let oref = t.test_oref(#"face", 1)

//   let oracleDatum1 = oracleDatum(1, 11111111, 15, 2)
//   let outDatum = InlineDatum(oracleDatum1)

//   let configIn = configInput()

//   let ownerInput =
//     t.test_input(
//       oref,
//       t.test_output(t.test_address(test_owner), t.makeAdaValue(10), NoDatum),
//     )

//   let oracleOutput =
//     t.test_output(
//       t.test_script_address(t.oracleValHash),
//       t.oracleValue(),
//       outDatum,
//     )

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       mint: t.oracleMintedValue(),
//       extra_signatories: [#"cafe"],
//       inputs: [ownerInput],
//       outputs: [oracleOutput],
//     }

//   let ctx = ScriptContext { purpose: Mint(t.oracleMintHash), transaction: tx }

//   oracleMint(test_owner, t.configMintHash, oracleMintActionMint(), ctx)?
// }
