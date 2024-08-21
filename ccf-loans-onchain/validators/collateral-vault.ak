use aiken/list
use aiken/pairs
use aiken/transaction.{
  InlineDatum, NoDatum, ScriptContext, Spend, Transaction, placeholder,
}
use aiken/transaction/credential.{Inline, ScriptCredential}
use aiken/transaction/value.{PolicyId}
use ccfl/types.{CollateralDatum, MerkelCollateralAction, MerkelConfigDatum}
use tests/tools as t
use tests/transactions as tx

validator(cp: PolicyId) {
  fn mCol(_d: CollateralDatum, r: MerkelCollateralAction, c: ScriptContext) {
    // True
    let ScriptContext { transaction, .. } = c
    let Transaction { reference_inputs, withdrawals, .. } = transaction

    expect Some(configIn) =
      list.find(
        reference_inputs,
        fn(input) { list.has(value.policies(input.output.value), cp) },
      )

    expect InlineDatum(datum) = configIn.output.datum
    expect cDatum: MerkelConfigDatum = datum

    expect Some(stakeVal) =
      cDatum.collateralRedeemers
        |> list.at(r.i)

    pairs.has_key(withdrawals, Inline(ScriptCredential(stakeVal)))
  }
}

test collateral_vault() {
  let configInDatum = tx.configDatumIn()

  let loanAction = tx.merkelCollateralAction(3)

  let collateralDatum = tx.collateralDatum(2000, 12, 0)
  let colOutDatum = InlineDatum(collateralDatum)
  let colOutValue = value.merge(t.makeAdaValue(2002), t.loanTokenValue())

  let userIn =
    t.test_input(
      tx.oref(#"beef", 2),
      t.test_output(t.test_address(#"cafe"), t.makeAdaValue(2010), NoDatum),
    )

  let configIn =
    t.test_input(
      tx.oref(#"aced", 1),
      t.test_output(
        t.test_script_address(t.configValHash),
        t.configValue(),
        configInDatum,
      ),
    )

  let loanIn =
    t.test_input(
      tx.oref(#"bead", 1),
      t.test_output(
        t.test_script_address(t.merkelCollateralSpend),
        colOutValue,
        InlineDatum(collateralDatum),
      ),
    )

  let loanOut =
    t.test_output(
      t.test_script_address(t.merkelCollateralSpend),
      colOutValue,
      colOutDatum,
    )

  let txn =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      inputs: [userIn, loanIn],
      outputs: [loanOut],
      withdrawals: tx.withdrawal(t.merkelBalance),
    }

  let scriptContext =
    ScriptContext { purpose: Spend(tx.oref(#"bead", 1)), transaction: txn }

  mCol(t.configMintHash, collateralDatum, loanAction, scriptContext)?
}
