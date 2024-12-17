use cardano/address.{Script}
use cardano/assets
use cardano/transaction.{InlineDatum, Transaction, placeholder}
use ccfl/typesv3.{MerkelConfigDatum, SupplyDatum}
use tests/scripts as s
use tests/tools as t
use tests/transactions as tx
use v3/close_pool

test close() {
  let loanHash = s.loan
  // let lpPolicy = s.supply
  let configPolicy = s.config
  // let wHash = #"bbbb"
  let oref = tx.oref(#"dddd", 2)
  // let loanTokenValue = assets.from_asset(loanHash, #"bbbb", 1)
  let oracleTokenMint = assets.from_asset(s.oracle, #"beef", -3)

  // let supplyAction = SLend { value: 10 }
  let inDatum = SupplyDatum { policy: #"deaf", asset: "" }

  // let outDatum = SupplyDatum { policy: #"deaf", asset: "" }
  // let loanDatum = tx.loanDatum(10, 10, 0, 2222222222222, #"beef")
  let configValue = assets.from_asset(s.config, "", 1)

  let configDatum =
    MerkelConfigDatum {
      loanVal: loanHash,
      colVal: s.collateral,
      oracleVal: s.oracle,
      interestVal: s.interest,
      supplyVal: s.supply,
      collateralRedeemers: [#"cccc", #"ffff", #"aaaa", #"bbbb"],
      supplyRedeemers: [#"cccc", #"ffff", #"aaaa", #"bbbb"],
    }

  let configIn =
    t.test_input(
      tx.oref(#"1111", 8),
      t.test_output(
        t.test_script_address(s.config),
        configValue,
        InlineDatum(configDatum),
      ),
    )

  let oracleInDatum = tx.oracleDatum(1000, 2222222222222, 0, 0, "USD")

  let oracleIn =
    t.test_input(
      tx.oref(#"dddd", 3),
      t.test_output(
        t.test_script_address(s.oracle),
        assets.from_asset(s.oracle, #"beef", 1),
        InlineDatum(oracleInDatum),
      ),
    )

  let interestDatum = tx.interestDatum(55, 70, 40, 300, 12)

  let interestIn =
    t.test_input(
      tx.oref(#"eeee", 4),
      t.test_output(
        t.test_script_address(s.interest),
        assets.from_asset(s.oracle, #"beef", 1),
        InlineDatum(interestDatum),
      ),
    )

  let supplyIn =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(s.supply),
        assets.from_asset(s.oracle, #"beef", 1),
        InlineDatum(inDatum),
      ),
    )

  let withdraw0 = tx.withdrawal(#"bebe")

  let redeemer = close_pool.CloseWithdraw { asset: #"beef" }

  let tx =
    Transaction {
      ..placeholder,
      inputs: [supplyIn, oracleIn, interestIn],
      mint: oracleTokenMint,
      reference_inputs: [configIn],
      withdrawals: withdraw0,
    }

  close_pool.close.withdraw(
    configPolicy,
    s.oracle,
    redeemer,
    Script(#"bebe"),
    tx,
  )?
}
