use cardano/assets
use cardano/transaction.{InlineDatum, Transaction, placeholder}
use ori/interest_vault
use tests/tools as t
use tests/transactions.{interestAction, interestDatum}

//                          //
// Interest Validator Tests //
//                          //

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
      ..placeholder,
      extra_signatories: [test_owner],
      inputs: [interestInput],
      outputs: [interestOutput],
    }

  interest_vault.interest.spend(
    t.oracleMintHash,
    test_owner,
    Some(interestDatum1),
    interestAction,
    oref,
    tx,
  )?
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
      ..placeholder,
      extra_signatories: [vulnSig],
      inputs: [interestInput],
      outputs: [interestOutput],
    }

  interest_vault.interest.spend(
    t.oracleMintHash,
    test_owner,
    Some(interestDatum1),
    interestAction,
    oref,
    tx,
  )
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
      ..placeholder,
      extra_signatories: [test_owner],
      inputs: [interestInput],
      outputs: [interestOutput],
    }

  interest_vault.interest.spend(
    t.oracleMintHash,
    test_owner,
    Some(interestDatum1),
    interestAction,
    oref,
    tx,
  )
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
      ..placeholder,
      extra_signatories: [test_owner],
      inputs: [interestInput],
      outputs: [interestOutput],
    }

  interest_vault.interest.spend(
    t.oracleMintHash,
    test_owner,
    Some(interestDatum1),
    interestAction,
    oref,
    tx,
  )
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
      ..placeholder,
      extra_signatories: [test_owner],
      inputs: [interestInput],
      outputs: [vulnOutput],
    }

  interest_vault.interest.spend(
    t.oracleMintHash,
    test_owner,
    Some(interestDatum1),
    interestAction,
    oref,
    tx,
  )?
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
      ..placeholder,
      extra_signatories: [test_owner],
      inputs: [interestInput, vulnInput],
      outputs: [interestOutput],
    }

  interest_vault.interest.spend(
    t.oracleMintHash,
    test_owner,
    Some(interestDatum1),
    interestAction,
    oref,
    tx,
  )?
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
      ..placeholder,
      extra_signatories: [test_owner],
      inputs: [interestInput],
      outputs: [vulnOutput],
    }

  interest_vault.interest.spend(
    t.oracleMintHash,
    test_owner,
    Some(interestDatum1),
    interestAction,
    oref,
    tx,
  )?
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
      assets.merge(
        assets.from_lovelace(2),
        assets.from_asset(t.oracleMintHash, #"cece", 1),
      ),
      outDatum,
    )

  let interestAction = interestAction(55, 70, 40, 300, 12)

  let tx =
    Transaction {
      ..placeholder,
      extra_signatories: [test_owner],
      inputs: [interestInput],
      outputs: [vulnOutput],
    }

  trace @"VULNERABILITY"
  interest_vault.interest.spend(
    t.oracleMintHash,
    test_owner,
    Some(interestDatum1),
    interestAction,
    oref,
    tx,
  )?
}
