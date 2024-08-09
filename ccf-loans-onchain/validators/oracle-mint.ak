use aiken/dict.{to_pairs}
use aiken/list
use aiken/transaction.{
  InlineDatum, Mint, NoDatum, ScriptContext, Transaction, placeholder,
}
use aiken/transaction/credential.{ScriptCredential}
use aiken/transaction/value.{PolicyId, from_minted_value, tokens}
use ccfl/types.{
  InterestDatum, MerkelConfigDatum, OBurn, OMint, OracleDatum, OracleMintAction,
  VerificationKeyHash,
}
use tests/tools as t
use tests/transactions.{configInput, interestDatum, oracleDatum}

//oracleMintActionMint,

//             //
// Oracle Mint //
//             //

validator(o: VerificationKeyHash, cp: PolicyId) {
  fn oracleMint(r: OracleMintAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Mint(policyId) = purpose

    expect [Pair(_oName, oAmt)] =
      transaction.mint
        |> from_minted_value()
        |> tokens(policyId)
        |> to_pairs()

    when r is {
      OMint {
        exchange,
        timestamp,
        currency,
        supply,
        borrowed,
        base,
        optimal,
        slope1,
        slope2,
        term,
      } -> {
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
              expect [Pair(_oName, 1)] =
                output.value
                  |> value.without_lovelace()
                  |> value.tokens(policyId)
                  |> dict.to_pairs()
              output.address.payment_credential == ScriptCredential(
                cDatum.oracleVal,
              )
            },
          )
        expect InlineDatum(datum) = out.datum
        expect oracleDatum: OracleDatum = datum

        expect oracleDatum.exchange == exchange
        expect oracleDatum.timestamp == timestamp
        expect oracleDatum.currency == currency
        expect oracleDatum.supply == supply
        expect oracleDatum.borrowed == borrowed

        expect Some(interest) =
          list.find(
            transaction.outputs,
            fn(output) {
              expect [Pair(_oName, 1)] =
                output.value
                  |> value.without_lovelace()
                  |> value.tokens(policyId)
                  |> dict.to_pairs()
              output.address.payment_credential == ScriptCredential(
                cDatum.interestVal,
              )
            },
          )
        expect InlineDatum(datum) = interest.datum
        expect interestDatum: InterestDatum = datum

        expect interestDatum.base == base
        expect interestDatum.optimal == optimal
        expect interestDatum.slope1 == slope1
        expect interestDatum.slope2 == slope2
        expect interestDatum.term == term

        list.has(transaction.extra_signatories, o) && oAmt == 2
      }
      OBurn -> list.has(transaction.extra_signatories, o) && oAmt == -2
    }
  }
}

//       //
// Tests //
//       //

test oracle_mint() {
  let test_owner = #"face"

  let exchange = 500
  let timestamp = 11111111
  let currency = "USD"
  let supply = 1000000
  let borrowed = 200000
  let base = 55
  let optimal = 70
  let slope1 = 40
  let slope2 = 300
  let term = 12

  let oracleMintAction =
    OMint {
      exchange,
      timestamp,
      currency,
      supply,
      borrowed,
      base,
      optimal,
      slope1,
      slope2,
      term,
    }

  let oref = t.test_oref(#"face", 1)

  let oracleDatum1 =
    oracleDatum(exchange, timestamp, supply, borrowed, currency)
  let interestDatum = interestDatum(base, optimal, slope1, slope2, term)
  let outDatum = InlineDatum(oracleDatum1)
  let configIn = configInput()

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

  let interestOutput =
    t.test_output(
      t.test_script_address(t.interestValHash),
      t.oracleValue(),
      InlineDatum(interestDatum),
    )

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      mint: t.oracleMintedValue(),
      extra_signatories: [test_owner],
      inputs: [ownerInput],
      outputs: [oracleOutput, interestOutput],
    }

  let ctx = ScriptContext { purpose: Mint(t.oracleMintHash), transaction: tx }

  oracleMint(test_owner, t.configMintHash, oracleMintAction, ctx)?
}
// test oracle_mint_qty_fail() fail {
//   let test_owner = #"face"

//   let oref = t.test_oref(#"face", 1)

//   let oracleDatum1 = oracleDatum(1, 11111111, 15, 2, #"beef")
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

//   let oracleDatum1 = oracleDatum(1, 11111111, 15, 2, #"beef")
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
