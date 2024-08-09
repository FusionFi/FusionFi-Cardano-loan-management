use aiken/dict.{to_pairs}
use aiken/list.{has}
use aiken/transaction.{
  InlineDatum, Input, Output, ScriptContext, Spend, Transaction, find_input,
  placeholder,
}
use aiken/transaction/value.{PolicyId, tokens, without_lovelace}
use ccfl/helpers.{get_own_singleton_output, has_singleton_input}
use ccfl/types.{
  InterestAction, InterestClose, InterestDatum, InterestUpdate,
  VerificationKeyHash,
}
use tests/tools as t
use tests/transactions.{interestAction, interestDatum}

// validator for handling updating and enforcing rates

validator(op: PolicyId, o: VerificationKeyHash) {
  fn interest(_d: InterestDatum, r: InterestAction, c: ScriptContext) {
    let ScriptContext { transaction, purpose } = c
    expect Spend(ownRef) = purpose

    expect has_singleton_input(transaction, ownRef)
    when r is {
      InterestUpdate { base, optimal, slope1, slope2, term } -> {
        let out = get_own_singleton_output(transaction, ownRef)

        expect [Pair(_, 1)] =
          without_lovelace(out.value)
            |> tokens(op)
            |> to_pairs()

        expect InlineDatum(datum) = out.datum
        expect datum: InterestDatum = datum

        has(transaction.extra_signatories, o) && datum.base == base && datum.optimal == optimal && datum.slope1 == slope1 && datum.slope2 == slope2 && datum.term == term
      }
      InterestClose -> {
        expect Some(ownIn) = find_input(transaction.inputs, ownRef)

        expect [Pair(inName, 1)] =
          // get singleton name
          without_lovelace(ownIn.output.value)
            |> tokens(op)
            |> to_pairs()

        expect [Pair(burnName, -2)] =
          transaction.mint
            |> value.from_minted_value()
            |> value.tokens(op)
            |> dict.to_pairs()

        has(transaction.extra_signatories, o) && inName == burnName
      }
    }
  }
}

//       //
// Tests //
//       //

test interestUpdate() {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)

  let interestDatum1 = interestDatum(55, 70, 40, 300, 12)
  let interestDatum2 = interestDatum(55, 70, 40, 300, 12)
  let inDatum = InlineDatum(interestDatum1)
  let outDatum = InlineDatum(interestDatum2)

  let interestInput =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(t.interestValHash),
        t.oracleValue(),
        inDatum,
      ),
    )

  let interestOutput =
    t.test_output(
      t.test_script_address(t.interestValHash),
      t.oracleValue(),
      outDatum,
    )

  let interestAction = interestAction(55, 70, 40, 300, 12)

  let tx =
    Transaction {
      ..placeholder(),
      extra_signatories: [test_owner],
      inputs: [interestInput],
      outputs: [interestOutput],
    }

  let ctx = ScriptContext { purpose: Spend(oref), transaction: tx }

  interest(t.oracleMintHash, test_owner, interestDatum1, interestAction, ctx)?
}

test interest_sigFail() fail {
  let test_owner = #"face"
  let vulnSig = #"aced"

  let oref = t.test_oref(#"face", 1)

  let interestDatum1 = interestDatum(55, 70, 40, 300, 12)
  let interestDatum2 = interestDatum(55, 70, 40, 300, 12)
  let inDatum = InlineDatum(interestDatum1)
  let outDatum = InlineDatum(interestDatum2)

  let interestInput =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(t.interestValHash),
        t.oracleValue(),
        inDatum,
      ),
    )

  let interestOutput =
    t.test_output(
      t.test_script_address(t.interestValHash),
      t.oracleValue(),
      outDatum,
    )

  let interestAction = interestAction(55, 70, 40, 300, 12)

  let tx =
    Transaction {
      ..placeholder(),
      extra_signatories: [vulnSig],
      inputs: [interestInput],
      outputs: [interestOutput],
    }

  let ctx = ScriptContext { purpose: Spend(oref), transaction: tx }

  interest(t.oracleMintHash, test_owner, interestDatum1, interestAction, ctx)
}

test interest_datumFail() fail {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)

  let interestDatum1 = interestDatum(55, 70, 40, 300, 12)
  let interestDatum2 = interestDatum(55, 70, 50, 300, 12)
  let inDatum = InlineDatum(interestDatum1)
  let outDatum = InlineDatum(interestDatum2)

  let interestInput =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(t.interestValHash),
        t.oracleValue(),
        inDatum,
      ),
    )

  let interestOutput =
    t.test_output(
      t.test_script_address(t.interestValHash),
      t.oracleValue(),
      outDatum,
    )

  let interestAction = interestAction(55, 70, 40, 300, 12)

  let tx =
    Transaction {
      ..placeholder(),
      extra_signatories: [test_owner],
      inputs: [interestInput],
      outputs: [interestOutput],
    }

  let ctx = ScriptContext { purpose: Spend(oref), transaction: tx }

  interest(t.oracleMintHash, test_owner, interestDatum1, interestAction, ctx)
}

test interest_actionFail() fail {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)

  let interestDatum1 = interestDatum(55, 70, 40, 300, 12)
  let interestDatum2 = interestDatum(55, 70, 40, 300, 12)
  let inDatum = InlineDatum(interestDatum1)
  let outDatum = InlineDatum(interestDatum2)

  let interestInput =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(t.interestValHash),
        t.oracleValue(),
        inDatum,
      ),
    )

  let interestOutput =
    t.test_output(
      t.test_script_address(t.interestValHash),
      t.oracleValue(),
      outDatum,
    )

  let interestAction = interestAction(55, 70, 50, 300, 12)

  let tx =
    Transaction {
      ..placeholder(),
      extra_signatories: [test_owner],
      inputs: [interestInput],
      outputs: [interestOutput],
    }

  let ctx = ScriptContext { purpose: Spend(oref), transaction: tx }

  interest(t.oracleMintHash, test_owner, interestDatum1, interestAction, ctx)
}

test interest_outputFail() fail {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)

  let interestDatum1 = interestDatum(55, 70, 40, 300, 12)
  let interestDatum2 = interestDatum(55, 70, 40, 300, 12)
  let inDatum = InlineDatum(interestDatum1)
  let outDatum = InlineDatum(interestDatum2)

  let interestInput =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(t.interestValHash),
        t.oracleValue(),
        inDatum,
      ),
    )

  let vulnOutput =
    t.test_output(
      t.test_script_address(t.loanValHash),
      t.oracleValue(),
      outDatum,
    )

  let interestAction = interestAction(55, 70, 40, 300, 12)

  let tx =
    Transaction {
      ..placeholder(),
      extra_signatories: [test_owner],
      inputs: [interestInput],
      outputs: [vulnOutput],
    }

  let ctx = ScriptContext { purpose: Spend(oref), transaction: tx }

  interest(t.oracleMintHash, test_owner, interestDatum1, interestAction, ctx)?
}

test interest_inputFail() fail {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)

  let interestDatum1 = interestDatum(55, 70, 40, 300, 12)
  let interestDatum2 = interestDatum(55, 70, 40, 300, 12)
  let inDatum = InlineDatum(interestDatum1)
  let outDatum = InlineDatum(interestDatum2)

  let interestInput =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(t.interestValHash),
        t.oracleValue(),
        inDatum,
      ),
    )

  let vulnInput =
    t.test_input(
      t.test_oref(#"aced", 1),
      t.test_output(
        t.test_script_address(t.interestValHash),
        t.oracleValue(),
        inDatum,
      ),
    )

  let interestOutput =
    t.test_output(
      t.test_script_address(t.loanValHash),
      t.oracleValue(),
      outDatum,
    )

  let interestAction = interestAction(55, 70, 40, 300, 12)

  let tx =
    Transaction {
      ..placeholder(),
      extra_signatories: [test_owner],
      inputs: [interestInput, vulnInput],
      outputs: [interestOutput],
    }

  let ctx = ScriptContext { purpose: Spend(oref), transaction: tx }

  interest(t.oracleMintHash, test_owner, interestDatum1, interestAction, ctx)?
}

test interest_outTokenFail() fail {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)

  let interestDatum1 = interestDatum(55, 70, 40, 300, 12)
  let interestDatum2 = interestDatum(55, 70, 40, 300, 12)
  let inDatum = InlineDatum(interestDatum1)
  let outDatum = InlineDatum(interestDatum2)

  let interestInput =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(t.interestValHash),
        t.oracleValue(),
        inDatum,
      ),
    )

  let vulnOutput =
    t.test_output(
      t.test_script_address(t.interestValHash),
      t.configValue(),
      outDatum,
    )

  let interestAction = interestAction(55, 70, 40, 300, 12)

  let tx =
    Transaction {
      ..placeholder(),
      extra_signatories: [test_owner],
      inputs: [interestInput],
      outputs: [vulnOutput],
    }

  let ctx = ScriptContext { purpose: Spend(oref), transaction: tx }

  interest(t.oracleMintHash, test_owner, interestDatum1, interestAction, ctx)?
}

test interest_tokenChange() {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)

  let interestDatum1 = interestDatum(55, 70, 40, 300, 12)
  let interestDatum2 = interestDatum(55, 70, 40, 300, 12)
  let inDatum = InlineDatum(interestDatum1)
  let outDatum = InlineDatum(interestDatum2)

  let interestInput =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(t.interestValHash),
        t.oracleValue(),
        inDatum,
      ),
    )

  let vulnOutput =
    t.test_output(
      t.test_script_address(t.interestValHash),
      value.merge(
        value.from_lovelace(2),
        value.from_asset(t.oracleMintHash, #"cece", 1),
      ),
      outDatum,
    )

  let interestAction = interestAction(55, 70, 40, 300, 12)

  let tx =
    Transaction {
      ..placeholder(),
      extra_signatories: [test_owner],
      inputs: [interestInput],
      outputs: [vulnOutput],
    }

  let ctx = ScriptContext { purpose: Spend(oref), transaction: tx }
  trace @"VULNERABILITY"
  interest(t.oracleMintHash, test_owner, interestDatum1, interestAction, ctx)?
}
