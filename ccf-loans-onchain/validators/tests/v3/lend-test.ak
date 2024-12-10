use cardano/address.{Script}
use cardano/assets
use cardano/transaction.{InlineDatum, NoDatum, Transaction, placeholder}
use ccfl/typesv3.{
  LoanDatum, MerkelConfigDatum, OracleDatum, SClose, SLend, SSupply, SWithdraw,
  SupplyDatum,
}
use tests/tools as t
use tests/transactions as tx
use v3/lend

test lend() {
  let loanHash = #"eeee"
  let lpPolicy = t.supplyHash
  let configPolicy = t.configMintHash
  let wHash = #"bbbb"
  let oref = tx.oref(#"dddd", 2)
  let loanTokenValue = assets.from_asset(loanHash, #"bbbb", 1)
  let loanTokenMint = assets.from_asset(loanHash, #"bbbb", 2)

  let supplyAction = SLend { value: 10 }

  let inDatum = SupplyDatum { policy: #"deaf", asset: "" }
  let outDatum = SupplyDatum { policy: #"deaf", asset: "" }

  let loanDatum = tx.loanDatum(10, 10, 0, 2222222222222, #"beef")

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
    tx.oracleDatum(1000, 2222222222222, 1000000, 200000, "USD")

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
    tx.oracleDatum(1000, 2222222222222, 1000000, 200010, "USD")

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
        t.test_script_address(lpPolicy),
        assets.merge(assets.from_asset(#"deaf", "", 1000010), t.oracleValue()),
        InlineDatum(inDatum),
      ),
    )

  let supplyOut =
    t.test_output(
      t.test_script_address(lpPolicy),
      assets.merge(assets.from_asset(#"deaf", "", 1000000), t.oracleValue()),
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
      assets.merge(assets.from_asset(#"deaf", "", 10), t.makeAdaValue(2)),
      NoDatum,
    )
  let loanOut =
    t.test_output(
      t.test_script_address(loanHash),
      loanTokenValue,
      InlineDatum(loanDatum),
    )

  let withdraw0 = tx.withdrawal(#"bebe")

  let redeemer = lend.WithdrawAction { a: 2, value: 10 }

  let tx =
    Transaction {
      ..placeholder,
      inputs: [supplyIn, oracleIn, userIn],
      outputs: [supplyOut, oracleOut, userOut, loanOut],
      mint: loanTokenMint,
      reference_inputs: [configIn],
      withdrawals: withdraw0,
    }

  lend.lend.withdraw(
    configPolicy,
    t.oracleMintHash,
    redeemer,
    Script(#"bebe"),
    tx,
  )?
}
