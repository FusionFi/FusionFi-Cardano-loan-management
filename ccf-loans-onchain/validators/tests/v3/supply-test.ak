use cardano/assets
use cardano/transaction.{InlineDatum, NoDatum, Transaction}
use ccfl/types.{OracleDatum, SSupply, SupplyDatum}
use supply/supply_pool
use tests/tools as tl
use tests/transactions as t

test supply() {
  let oPolicy = #"0000"
  let lpPolicy = #"1111"

  let supplyAction = SSupply
  10
  let inDatum = SupplyDatum { policy: #"deaf", asset: "", oracle: #"beef" }

  let outDatum = SupplyDatum { policy: #"deaf", asset: "", oracle: #"beef" }

  let lpMintValue = assets.from_asset(lpPolicy, "", 10)

  let oracleIn = t.oracleInput(1000)
  let oracleOutDatum =
    t.oracleDatum(1000, 2222222222222, 1000010, 200000, "USD")

  let oracleOut =
    tl.test_output(
      tl.test_script_address(tl.oracleValHash),
      tl.oracleValue(),
      oracleOutDatum,
    )
  let supplyIn =
    tl.test_input(
      oref,
      tl.test_output(
        tl.test_script_address(#"face"),
        assets.merge(
          assets.from_asset(#"deaf", "", 1000000),
          tl.makeAdaValue(2),
        ),
        InlineDatum(inDatum),
      ),
    )

  let supplyOut =
    tl.test_input(
      oref,
      tl.test_output(
        tl.test_script_address(#"face"),
        assets.merge(
          assets.from_asset(#"deaf", "", 1000010),
          tl.makeAdaValue(2),
        ),
        InlineDatum(outDatum),
      ),
    )

  let userIn =
    tl.test_input(
      #"2222",
      tl.test_output(
        tl.test_address(#"cafe"),
        assets.merge(assets.from_asset(#"deaf", "", 10), tl.makeAdaValue(2)),
        NoDatum,
      ),
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

  supply - pool.supplyPool.spend(
    #"face",
    tl.oracleMintHash,
    Some(inDatum),
    supplyAction,
    oref,
    tx,
  )
}
