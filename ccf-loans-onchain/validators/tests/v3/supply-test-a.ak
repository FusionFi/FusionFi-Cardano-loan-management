use cardano/assets
use cardano/transaction.{InlineDatum, NoDatum, Transaction, placeholder}
use ccfl/types.{SClose, SLend, SSupply, SWithdraw, SupplyDatum}
use tests/tools as tl
use tests/transactions as t
use v3/supply_pool_a

test supply() {
  let loanHash = #"eeee"
  let oPolicy = #"0000"
  let lpPolicy = tl.supplyHash
  let oref = t.oref(#"dddd", 2)

  let supplyAction = SSupply { value: 10 }

  let inDatum = SupplyDatum { policy: #"deaf", asset: "", oracle: #"beef" }

  let outDatum = SupplyDatum { policy: #"deaf", asset: "", oracle: #"beef" }

  let lpMintValue = assets.from_asset(lpPolicy, #"deaf", 10)

  let oracleInDatum =
    t.oracleDatum(1000, 2222222222222, 1000000, 200000, #"deaf")

  let oracleIn =
    tl.test_input(
      t.oref(#"1111", 1),
      tl.test_output(
        tl.test_script_address(tl.oracleValHash),
        tl.oracleValue(),
        InlineDatum(oracleInDatum),
      ),
    )

  let oracleOutDatum =
    t.oracleDatum(1000, 2222222222222, 1000010, 200000, #"deaf")

  let oracleOut =
    tl.test_output(
      tl.test_script_address(tl.oracleValHash),
      tl.oracleValue(),
      InlineDatum(oracleOutDatum),
    )

  let supplyIn =
    tl.test_input(
      oref,
      tl.test_output(
        tl.test_script_address(tl.supplyHash),
        assets.merge(
          assets.from_asset(#"deaf", "", 1000000),
          tl.makeAdaValue(2),
        ),
        InlineDatum(inDatum),
      ),
    )

  let supplyOut =
    tl.test_output(
      tl.test_script_address(tl.supplyHash),
      assets.merge(assets.from_asset(#"deaf", "", 1000010), tl.makeAdaValue(2)),
      InlineDatum(outDatum),
    )

  let userIn =
    tl.test_input(
      t.oref(#"2222", 2),
      tl.test_output(tl.test_address(#"cafe"), tl.makeAdaValue(2), NoDatum),
    )

  let userOut =
    tl.test_output(
      tl.test_address(#"cafe"),
      assets.merge(lpMintValue, tl.makeAdaValue(2)),
      NoDatum,
    )

  let tx =
    Transaction {
      ..placeholder,
      inputs: [supplyIn, oracleIn, userIn],
      outputs: [supplyOut, oracleOut, userOut],
      mint: lpMintValue,
    }

  supply_pool_a.supplyPool.spend(
    #"face",
    tl.oracleMintHash,
    loanHash,
    Some(inDatum),
    supplyAction,
    oref,
    tx,
  )
}

test withdraw() {
  let loanHash = #"eeee"
  let lpPolicy = tl.supplyHash
  let oref = t.oref(#"dddd", 2)

  let supplyAction = SWithdraw { value: 10 }

  let inDatum = SupplyDatum { policy: #"deaf", asset: "", oracle: #"beef" }

  let outDatum = SupplyDatum { policy: #"deaf", asset: "", oracle: #"beef" }

  let lpMintValue = assets.from_asset(lpPolicy, #"deaf", -10)

  let oracleInDatum =
    t.oracleDatum(1000, 2222222222222, 1000010, 200000, #"deaf")

  let oracleIn =
    tl.test_input(
      t.oref(#"dddd", 3),
      tl.test_output(
        tl.test_script_address(tl.oracleValHash),
        tl.oracleValue(),
        InlineDatum(oracleInDatum),
      ),
    )
  let oracleOutDatum =
    t.oracleDatum(1000, 2222222222222, 1000000, 200000, #"deaf")

  let oracleOut =
    tl.test_output(
      tl.test_script_address(tl.oracleValHash),
      tl.oracleValue(),
      InlineDatum(oracleOutDatum),
    )

  let supplyIn =
    tl.test_input(
      oref,
      tl.test_output(
        tl.test_script_address(tl.supplyHash),
        assets.merge(
          assets.from_asset(#"deaf", "", 1000010),
          tl.makeAdaValue(2),
        ),
        InlineDatum(inDatum),
      ),
    )

  let supplyOut =
    tl.test_output(
      tl.test_script_address(tl.supplyHash),
      assets.merge(assets.from_asset(#"deaf", "", 1000000), tl.makeAdaValue(2)),
      InlineDatum(outDatum),
    )

  let userIn =
    tl.test_input(
      t.oref(#"2222", 2),
      tl.test_output(
        tl.test_address(#"cafe"),
        assets.merge(
          assets.from_asset(lpPolicy, #"deaf", 10),
          tl.makeAdaValue(2),
        ),
        NoDatum,
      ),
    )

  let userOut =
    tl.test_output(
      tl.test_address(#"cafe"),
      assets.merge(assets.from_asset(#"deaf", "", 10), tl.makeAdaValue(2)),
      NoDatum,
    )

  let tx =
    Transaction {
      ..placeholder,
      inputs: [supplyIn, oracleIn, userIn],
      outputs: [supplyOut, oracleOut, userOut],
      mint: lpMintValue,
    }

  supply_pool_a.supplyPool.spend(
    #"face",
    tl.oracleMintHash,
    loanHash,
    Some(inDatum),
    supplyAction,
    oref,
    tx,
  )
}

test lend() {
  let loanHash = #"eeee"
  let lpPolicy = tl.supplyHash
  let oref = t.oref(#"dddd", 2)
  let loanTokenValue = assets.from_asset(loanHash, #"bbbb", 1)
  let loanTokenMint = assets.from_asset(loanHash, #"bbbb", 2)

  let supplyAction = SLend { value: 10 }

  let inDatum = SupplyDatum { policy: #"deaf", asset: "", oracle: #"beef" }
  let outDatum = SupplyDatum { policy: #"deaf", asset: "", oracle: #"beef" }

  let loanDatum = t.loanDatum(10, 10, 0, 2222222222222, #"beef")
  let oracleInDatum = t.oracleDatum(1000, 2222222222222, 1000000, 200000, "USD")

  let oracleIn =
    tl.test_input(
      t.oref(#"dddd", 3),
      tl.test_output(
        tl.test_script_address(tl.oracleValHash),
        tl.oracleValue(),
        InlineDatum(oracleInDatum),
      ),
    )
  let oracleOutDatum =
    t.oracleDatum(1000, 2222222222222, 1000000, 200010, "USD")

  let oracleOut =
    tl.test_output(
      tl.test_script_address(tl.oracleValHash),
      tl.oracleValue(),
      InlineDatum(oracleOutDatum),
    )

  let supplyIn =
    tl.test_input(
      oref,
      tl.test_output(
        tl.test_script_address(lpPolicy),
        assets.merge(
          assets.from_asset(#"deaf", "", 1000010),
          tl.makeAdaValue(2),
        ),
        InlineDatum(inDatum),
      ),
    )

  let supplyOut =
    tl.test_output(
      tl.test_script_address(lpPolicy),
      assets.merge(assets.from_asset(#"deaf", "", 1000000), tl.makeAdaValue(2)),
      InlineDatum(outDatum),
    )

  let userIn =
    tl.test_input(
      t.oref(#"2222", 2),
      tl.test_output(tl.test_address(#"cafe"), tl.makeAdaValue(2), NoDatum),
    )

  let userOut =
    tl.test_output(
      tl.test_address(#"cafe"),
      assets.merge(assets.from_asset(#"deaf", "", 10), tl.makeAdaValue(2)),
      NoDatum,
    )
  let loanOut =
    tl.test_output(
      tl.test_script_address(loanHash),
      loanTokenValue,
      InlineDatum(loanDatum),
    )

  let tx =
    Transaction {
      ..placeholder,
      inputs: [supplyIn, oracleIn, userIn],
      outputs: [supplyOut, oracleOut, userOut, loanOut],
      mint: loanTokenMint,
    }

  supply_pool_a.supplyPool.spend(
    #"face",
    tl.oracleMintHash,
    loanHash,
    Some(inDatum),
    supplyAction,
    oref,
    tx,
  )
}

test close() {
  let loanHash = #"eeee"
  let lpPolicy = tl.supplyHash
  let oref = t.oref(#"dddd", 2)

  let supplyAction = SClose

  let inDatum = SupplyDatum { policy: #"deaf", asset: "", oracle: #"beef" }

  let outDatum = SupplyDatum { policy: #"deaf", asset: "", oracle: #"beef" }

  // let lpMintValue = assets.from_asset(lpPolicy, #"deaf", 10)
  let oracleBurnValue = assets.from_asset(tl.oracleMintHash, #"beef", -2)

  let oracleInDatum = t.oracleDatum(1000, 2222222222222, 0, 0, "USD")

  let oracleIn =
    tl.test_input(
      t.oref(#"dddd", 3),
      tl.test_output(
        tl.test_script_address(tl.oracleValHash),
        tl.oracleValue(),
        InlineDatum(oracleInDatum),
      ),
    )

  let supplyIn =
    tl.test_input(
      oref,
      tl.test_output(
        tl.test_script_address(#"face"),
        assets.merge(assets.from_asset(#"deaf", "", 0), tl.makeAdaValue(2)),
        InlineDatum(inDatum),
      ),
    )

  let supplyOut =
    tl.test_output(
      tl.test_script_address(#"face"),
      assets.merge(assets.from_asset(#"deaf", "", 0), tl.makeAdaValue(2)),
      InlineDatum(outDatum),
    )

  let tx =
    Transaction {
      ..placeholder,
      inputs: [supplyIn, oracleIn],
      outputs: [supplyOut],
      mint: oracleBurnValue,
    }

  supply_pool_a.supplyPool.spend(
    #"face",
    tl.oracleMintHash,
    loanHash,
    Some(inDatum),
    supplyAction,
    oref,
    tx,
  )?
}
