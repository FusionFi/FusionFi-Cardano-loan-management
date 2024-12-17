use cardano/address.{Script}
use cardano/assets
use cardano/transaction.{InlineDatum, NoDatum, Transaction, placeholder}
use ccfl/types.{Withdraw}
use ccfl/typesv3.{MerkelConfigDatum, SupplyDatum}
use tests/scripts as s
use tests/tools as t
use tests/transactions as tx
use v3/supply

test supply() {
  let loanHash = s.loan
  // let oPolicy = #"0000"
  let lpPolicy = s.supply
  let configPolicy = s.config
  // let wHash = #"bbbb"
  let oref = tx.oref(#"dddd", 2)

  // let supplyAction = SSupply { value: 10 }
  let inDatum = SupplyDatum { policy: #"deaf", asset: "" }

  let outDatum = SupplyDatum { policy: #"deaf", asset: "" }

  let lpMintValue = assets.from_asset(lpPolicy, #"deaf", 10)
  let oracleValue = assets.from_asset(s.oracle, #"beef", 1)
  let configValue = assets.from_asset(configPolicy, "", 1)

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
        t.test_script_address(configPolicy),
        configValue,
        InlineDatum(configDatum),
      ),
    )

  let oracleInDatum =
    tx.oracleDatum(1000, 2222222222222, 1000000, 200000, #"deaf")

  let oracleIn =
    t.test_input(
      tx.oref(#"1111", 1),
      t.test_output(
        t.test_script_address(s.oracle),
        oracleValue,
        InlineDatum(oracleInDatum),
      ),
    )

  let oracleOutDatum =
    tx.oracleDatum(1000, 2222222222222, 1000010, 200000, #"deaf")

  let oracleOut =
    t.test_output(
      t.test_script_address(s.oracle),
      oracleValue,
      InlineDatum(oracleOutDatum),
    )

  let supplyIn =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(s.supply),
        assets.merge(assets.from_asset(#"deaf", "", 1000000), oracleValue),
        InlineDatum(inDatum),
      ),
    )

  let supplyOut =
    t.test_output(
      t.test_script_address(s.supply),
      assets.merge(assets.from_asset(#"deaf", "", 1000010), oracleValue),
      InlineDatum(outDatum),
    )

  let userIn =
    t.test_input(
      tx.oref(#"2222", 2),
      t.test_output(t.test_address(#"cafe"), t.makeAdaValue(2), NoDatum),
    )

  let userOut =
    t.test_output(
      t.test_address(#"cafe"),
      assets.merge(lpMintValue, t.makeAdaValue(2)),
      NoDatum,
    )

  let withdraw0 = tx.withdrawal(#"bebe")

  let redeemer = Withdraw { a: [1, 2, 3] }

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      inputs: [supplyIn, oracleIn, userIn],
      outputs: [supplyOut, oracleOut, userOut],
      mint: lpMintValue,
      withdrawals: withdraw0,
    }

  supply.supply.withdraw(configPolicy, s.oracle, redeemer, Script(#"bebe"), tx)?
}
