use cardano/assets
use cardano/transaction.{InlineDatum, NoDatum, Transaction, placeholder}
use tests/prop
use tests/tools as t
use tests/transactions as tx
use v1/collateral_vault

//                        //
// Collateral Valut Tests //
//                        //

test collateral_vault((p1, p2) via prop.colFuzz()) {
  let configInDatum = tx.configDatumIn()

  let loanAction = tx.merkelCollateralAction(3)

  let collateralDatum = tx.collateralDatum(p1, 12, 0)
  let colOutDatum = InlineDatum(collateralDatum)
  let colOutValue = assets.merge(t.makeAdaValue(p2), t.loanTokenValue())

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
      ..placeholder,
      reference_inputs: [configIn],
      inputs: [userIn, loanIn],
      outputs: [loanOut],
      withdrawals: tx.withdrawal(t.merkelBalance),
    }

  collateral_vault.collateral.spend(
    t.configMintHash,
    Some(collateralDatum),
    loanAction,
    tx.oref(#"bead", 1),
    txn,
  )?
}
