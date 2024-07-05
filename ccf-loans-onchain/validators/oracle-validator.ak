use aiken/dict.{to_pairs}
use aiken/list.{has}
use aiken/transaction.{
  InlineDatum, Input, Output, ScriptContext, Spend, Transaction, find_input,
  placeholder,
}
use aiken/transaction/value.{PolicyId, tokens, without_lovelace}
use ccfl/helpers.{get_own_singleton_output, has_singleton_input}
use ccfl/types.{
  OracleAction, OracleClose, OracleDatum, OracleUpdate, VerificationKeyHash,
}
use tests/tools as t
use tests/transactions.{oracleAction, oracleDatum}

//                  //
// Oracle Validator //
//                  //

validator(o: VerificationKeyHash, p: PolicyId) {
  fn oracleVault(d: OracleDatum, r: OracleAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Spend(ownRef) = purpose

    expect has_singleton_input(transaction, ownRef)
    when r is {
      OracleUpdate { exchange, timestamp, interest, fee } -> {
        let out = get_own_singleton_output(transaction, ownRef)

        expect [Pair(_, 1)] =
          without_lovelace(out.value)
            |> tokens(p)
            |> to_pairs()

        expect InlineDatum(datum) = out.datum
        expect datum: OracleDatum = datum

        has(transaction.extra_signatories, o) && timestamp > d.timestamp && interest >= 0 && fee >= 0 && datum.exchange == exchange && datum.timestamp == timestamp && datum.currency == d.currency && datum.fee == fee
      }
      OracleClose -> {
        expect Some(input) = find_input(transaction.inputs, ownRef)

        expect [Pair(inName, 1)] =
          // get singleton name
          without_lovelace(input.output.value)
            |> tokens(p)
            |> to_pairs()

        expect [Pair(burnName, -1)] =
          transaction.mint
            |> value.from_minted_value()
            |> value.tokens(p)
            |> dict.to_pairs()

        has(transaction.extra_signatories, o) && inName == burnName
      }
    }
  }
}
//       //
// Tests //
//       //

// test oracle_vault() {
//   let test_owner = #"face"

//   let oref = t.test_oref(#"face", 1)

//   let oracleDatum1 = oracleDatum(1, 11111111, 15, 2, "beef")
//   let oracleDatum2 = oracleDatum(2, 11111112, 15, 2, "beef")
//   let inDatum = InlineDatum(oracleDatum1)
//   let outDatum = InlineDatum(oracleDatum2)

//   let oracleInput =
//     t.test_input(
//       oref,
//       t.test_output(
//         t.test_script_address(t.oracleValHash),
//         t.oracleValue(),
//         inDatum,
//       ),
//     )

//   let oracleOutput =
//     t.test_output(
//       t.test_script_address(t.oracleValHash),
//       t.oracleValue(),
//       outDatum,
//     )

//   let oracleAction = oracleAction(2, 11111112, 15, 2)

//   let tx =
//     Transaction {
//       ..placeholder(),
//       extra_signatories: [test_owner],
//       inputs: [oracleInput],
//       outputs: [oracleOutput],
//     }

//   let ctx = ScriptContext { purpose: Spend(oref), transaction: tx }

//   oracleVault(test_owner, t.oracleMintHash, oracleDatum1, oracleAction, ctx)?
// }

// test oracle_vault_datum_fail() fail {
//   let test_owner = #"face"

//   let oref = t.test_oref(#"face", 1)

//   let oracleDatum1 = oracleDatum(1, 11111111, 15, 2)
//   let oracleDatum2 = oracleDatum(1, 11111112, 15, 2)
//   let inDatum = InlineDatum(oracleDatum1)
//   let outDatum = InlineDatum(oracleDatum2)

//   let oracleInput =
//     t.test_input(
//       oref,
//       t.test_output(
//         t.test_script_address(t.oracleValHash),
//         t.oracleValue(),
//         inDatum,
//       ),
//     )

//   let oracleOutput =
//     t.test_output(
//       t.test_script_address(t.oracleValHash),
//       t.oracleValue(),
//       outDatum,
//     )

//   let oracleAction = oracleAction(2, 11111112, 15, 2)

//   let tx =
//     Transaction {
//       ..placeholder(),
//       extra_signatories: [test_owner],
//       inputs: [oracleInput],
//       outputs: [oracleOutput],
//     }

//   let ctx = ScriptContext { purpose: Spend(oref), transaction: tx }

//   oracleVault(test_owner, t.oracleMintHash, oracleDatum1, oracleAction, ctx)?
// }

// test oracle_vault_redeemer_fail() fail {
//   let test_owner = #"face"

//   let oref = t.test_oref(#"face", 1)

//   let oracleDatum1 = oracleDatum(1, 11111111, 15, 2)
//   let oracleDatum2 = oracleDatum(2, 11111112, 15, 2)
//   let inDatum = InlineDatum(oracleDatum1)
//   let outDatum = InlineDatum(oracleDatum2)

//   let oracleInput =
//     t.test_input(
//       oref,
//       t.test_output(
//         t.test_script_address(t.oracleValHash),
//         t.oracleValue(),
//         inDatum,
//       ),
//     )

//   let oracleOutput =
//     t.test_output(
//       t.test_script_address(t.oracleValHash),
//       t.oracleValue(),
//       outDatum,
//     )

//   let oracleAction = oracleAction(1, 11111112, 15, 2)

//   let tx =
//     Transaction {
//       ..placeholder(),
//       extra_signatories: [test_owner],
//       inputs: [oracleInput],
//       outputs: [oracleOutput],
//     }

//   let ctx = ScriptContext { purpose: Spend(oref), transaction: tx }

//   oracleVault(test_owner, t.oracleMintHash, oracleDatum1, oracleAction, ctx)?
// }

// test oracle_vault_sig_fail() fail {
//   let test_owner = #"face"

//   let oref = t.test_oref(#"face", 1)

//   let oracleDatum1 = oracleDatum(1, 11111111, 15, 2)
//   let oracleDatum2 = oracleDatum(2, 11111112, 15, 2)
//   let inDatum = InlineDatum(oracleDatum1)
//   let outDatum = InlineDatum(oracleDatum2)

//   let oracleInput =
//     t.test_input(
//       oref,
//       t.test_output(
//         t.test_script_address(t.oracleValHash),
//         t.oracleValue(),
//         inDatum,
//       ),
//     )

//   let oracleOutput =
//     t.test_output(
//       t.test_script_address(t.oracleValHash),
//       t.oracleValue(),
//       outDatum,
//     )

//   let oracleAction = oracleAction(2, 11111112, 15, 2)

//   let tx =
//     Transaction {
//       ..placeholder(),
//       extra_signatories: [#"dead"],
//       inputs: [oracleInput],
//       outputs: [oracleOutput],
//     }

//   let ctx = ScriptContext { purpose: Spend(oref), transaction: tx }

//   oracleVault(test_owner, t.oracleMintHash, oracleDatum1, oracleAction, ctx)?
// }

// test oracle_vault_token_fail() fail {
//   let test_owner = #"face"

//   let oref = t.test_oref(#"face", 1)

//   let oracleDatum1 = oracleDatum(1, 11111111, 15, 2)
//   let oracleDatum2 = oracleDatum(2, 11111112, 15, 2)
//   let inDatum = InlineDatum(oracleDatum1)
//   let outDatum = InlineDatum(oracleDatum2)

//   let oracleInput =
//     t.test_input(
//       oref,
//       t.test_output(
//         t.test_script_address(t.oracleValHash),
//         t.oracleValue(),
//         inDatum,
//       ),
//     )

//   let oracleOutput =
//     t.test_output(
//       t.test_script_address(t.oracleValHash),
//       t.makeAdaValue(2),
//       outDatum,
//     )

//   let oracleAction = oracleAction(2, 11111112, 15, 2)

//   let tx =
//     Transaction {
//       ..placeholder(),
//       extra_signatories: [test_owner],
//       inputs: [oracleInput],
//       outputs: [oracleOutput],
//     }

//   let ctx = ScriptContext { purpose: Spend(oref), transaction: tx }

//   oracleVault(test_owner, t.oracleMintHash, oracleDatum1, oracleAction, ctx)?
// }
