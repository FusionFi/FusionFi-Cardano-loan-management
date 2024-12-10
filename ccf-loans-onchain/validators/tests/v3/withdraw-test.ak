use cardano/address.{Script}
use cardano/assets
use cardano/transaction.{InlineDatum, NoDatum, Transaction, placeholder}
use ccfl/types
use ccfl/typesv3.{
  MerkelConfigDatum, SClose, SLend, SSupply, SWithdraw, SupplyDatum,
}
use tests/tools as t
use tests/transactions as tx
use v3/withdraw

test withdraw() {
  let loanHash = #"eeee"
  let lpPolicy = t.supplyHash
  let configPolicy = t.configMintHash
  let wHash = #"bbbb"
  let oref = tx.oref(#"dddd", 2)

  let supplyAction = SWithdraw { value: 10 }

  let inDatum = SupplyDatum { policy: #"deaf", asset: "" }

  let outDatum = SupplyDatum { policy: #"deaf", asset: "" }

  let lpMintValue = assets.from_asset(lpPolicy, #"deaf", -10)

  let configValue = assets.from_asset(configPolicy, "", 1)

  let configDatum =
    MerkelConfigDatum {
      loanVal: loanHash,
      colVal: t.mCol,
      oracleVal: t.oracleValHash,
      interestVal: t.interestValHash,
      supplyVal: t.supplyHash,
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
    tx.oracleDatum(1000, 2222222222222, 1000010, 200000, #"deaf")

  let oracleIn =
    t.test_input(
      tx.oref(#"dddd", 3),
      t.test_output(
        t.test_script_address(t.oracleValHash),
        t.oracleValue(),
        InlineDatum(oracleInDatum),
      ),
    )

  let oracleOutDatum =
    tx.oracleDatum(1000, 2222222222222, 1000000, 200000, #"deaf")

  let oracleOut =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      t.oracleValue(),
      InlineDatum(oracleOutDatum),
    )

  let supplyIn =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(t.supplyHash),
        assets.merge(assets.from_asset(#"deaf", "", 1000010), t.oracleValue()),
        InlineDatum(inDatum),
      ),
    )

  let supplyOut =
    t.test_output(
      t.test_script_address(t.supplyHash),
      assets.merge(assets.from_asset(#"deaf", "", 1000000), t.oracleValue()),
      InlineDatum(outDatum),
    )

  let userIn =
    t.test_input(
      tx.oref(#"2222", 2),
      t.test_output(
        t.test_address(#"cafe"),
        assets.merge(
          assets.from_asset(lpPolicy, #"deaf", 10),
          t.makeAdaValue(2),
        ),
        NoDatum,
      ),
    )

  let userOut =
    t.test_output(
      t.test_address(#"cafe"),
      assets.merge(assets.from_asset(#"deaf", "", 10), t.makeAdaValue(2)),
      NoDatum,
    )

  let withdraw0 = tx.withdrawal(#"bebe")

  let redeemer = withdraw.WithdrawAction { a: 2, value: 10 }

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      inputs: [supplyIn, oracleIn, userIn],
      outputs: [supplyOut, oracleOut, userOut],
      mint: lpMintValue,
      withdrawals: withdraw0,
    }

  withdraw.withdraw.withdraw(
    configPolicy,
    t.oracleMintHash,
    redeemer,
    Script(#"bebe"),
    tx,
  )?
}
