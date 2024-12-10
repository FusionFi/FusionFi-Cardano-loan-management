use cardano/transaction.{InlineDatum, Transaction, placeholder}
use tests/tools as t
use tests/transactions.{interestAction, interestDatum}
use v1/interest_vault

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
