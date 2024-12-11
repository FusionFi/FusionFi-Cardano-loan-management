use cardano/address.{Script}
use cardano/assets
use cardano/transaction.{InlineDatum, Transaction, placeholder}
use ccfl/typesv3.{MerkelConfigDatum, SupplyDatum}
use tests/tools as t
use tests/transactions as tx
use v3/close

test close() {
  let loanHash = #"eeee"
  let lpPolicy = t.supplyHash
  let configPolicy = t.configMintHash
  // let wHash = #"bbbb"
  let oref = tx.oref(#"dddd", 2)
  // let loanTokenValue = assets.from_asset(loanHash, #"bbbb", 1)
  let oracleTokenMint = assets.from_asset(t.oracleMintHash, #"beef", -3)

  // let supplyAction = SLend { value: 10 }
  let inDatum = SupplyDatum { policy: #"deaf", asset: "" }

  // let outDatum = SupplyDatum { policy: #"deaf", asset: "" }
  // let loanDatum = tx.loanDatum(10, 10, 0, 2222222222222, #"beef")
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

  let oracleInDatum = tx.oracleDatum(1000, 2222222222222, 0, 0, "USD")

  let oracleIn =
    t.test_input(
      tx.oref(#"dddd", 3),
      t.test_output(
        t.test_script_address(t.oracleValHash),
        t.oracleValue(),
        InlineDatum(oracleInDatum),
      ),
    )

  let interestDatum = tx.interestDatum(55, 70, 40, 300, 12)

  let interestIn =
    t.test_input(
      tx.oref(#"eeee", 4),
      t.test_output(
        t.test_script_address(t.interestValHash),
        t.oracleValue(),
        InlineDatum(interestDatum),
      ),
    )

  let supplyIn =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(lpPolicy),
        t.oracleValue(),
        InlineDatum(inDatum),
      ),
    )

  let withdraw0 = tx.withdrawal(#"bebe")

  let redeemer = close.CloseWithdraw { asset: #"beef" }

  let tx =
    Transaction {
      ..placeholder,
      inputs: [supplyIn, oracleIn, interestIn],
      mint: oracleTokenMint,
      reference_inputs: [configIn],
      withdrawals: withdraw0,
    }

  close.close.withdraw(
    configPolicy,
    t.oracleMintHash,
    redeemer,
    Script(#"bebe"),
    tx,
  )?
}
