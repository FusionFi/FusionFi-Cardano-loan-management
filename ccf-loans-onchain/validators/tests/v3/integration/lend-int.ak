use cardano/address.{Script}
use cardano/assets
use cardano/transaction.{InlineDatum, NoDatum, Transaction, placeholder}
use ccfl/typesv3.{
  AMint, LoanDatum, MerkelConfigDatum, OracleDatum, OracleUpdate, SupplyDatum,
}
use tests/scripts as s
use tests/tools as t
use tests/v3 as v
use v3/lend
use v3/loan.{FMint}
use v3/oracle

test lend() {
  let owner = #"ffff"
  let inRatio = 1000
  let outRatio = 1000

  let outLoanAmount = 1000
  let outCollateralAmount = 2000
  let outCollateralValue = 4000

  let loanHash = s.loan
  // let lpPolicy = s.supply
  let configPolicy = s.config
  // let wHash = #"bbbb"
  let oref = v.oref(#"dddd", 2)
  let loanTokenValue = assets.from_asset(loanHash, #"bbbb", 1)
  let loanTokenMint = assets.from_asset(loanHash, #"bbbb", 2)

  // let supplyAction = SLend { value: 10 }
  let inDatum = SupplyDatum { policy: #"deaf", asset: "" }
  let outDatum = SupplyDatum { policy: #"deaf", asset: "" }

  let loanDatum = LoanDatum(1000, 1000, 0, 2222222222222, #"beef", #"cafe")

  let configValue = assets.from_asset(configPolicy, "", 1)
  let oracleValue = assets.from_asset(s.oracle, #"beef", 1)

  let configDatum =
    MerkelConfigDatum {
      loanVal: loanHash,
      colVal: s.collateral,
      oracleVal: s.oracle,
      interestVal: s.interest,
      supplyVal: s.supply,
      collateralRedeemers: [#"cccc", #"ffff", #"aaaa", #"bbbb"],
      supplyRedeemers: [#"bebe", #"ffff", #"aaaa", #"bbbb"],
    }

  let configIn =
    t.test_input(
      v.oref(#"1111", 8),
      t.test_output(
        t.test_script_address(configPolicy),
        configValue,
        InlineDatum(configDatum),
      ),
    )

  let oracleDatumIn =
    OracleDatum(inRatio, 1111111111111, "USD", 1001000, 200000)

  let oracleIn =
    t.test_input(
      v.oref(#"dead", 6),
      t.test_output(
        t.test_script_address(s.oracle),
        assets.from_asset(s.oracle, #"beef", 1),
        InlineDatum(oracleDatumIn),
      ),
    )

  let oracleOutDatum =
    v.oracleDatum(outRatio, 2222222222222, "USD", 1000000, 201000)

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
        assets.merge(assets.from_asset(#"deaf", "", 101000), oracleValue),
        InlineDatum(inDatum),
      ),
    )

  let supplyOut =
    t.test_output(
      t.test_script_address(s.supply),
      assets.merge(assets.from_asset(#"deaf", "", 1000000), oracleValue),
      InlineDatum(outDatum),
    )

  let userIn =
    t.test_input(
      v.oref(#"2222", 2),
      t.test_output(t.test_address(#"cafe"), t.makeAdaValue(2), NoDatum),
    )

  let userOut =
    t.test_output(
      t.test_address(#"cafe"),
      assets.merge(assets.from_asset(#"deaf", "", 1000), t.makeAdaValue(2)),
      NoDatum,
    )

  let loanOut =
    t.test_output(
      t.test_script_address(loanHash),
      loanTokenValue,
      InlineDatum(loanDatum),
    )

  let withdraw0 = v.withdrawal(#"bebe")

  // let mintAction = AMint(1000, 1000, 0, 2222222222222, #"cafe")
  let mintAction = FMint(0)
  let oracleAction = OracleUpdate(1000, 2222222222222, 1000000, 1000)
  let redeemer = lend.WithdrawAction { a: 2, value: 1000 }

  let tx =
    Transaction {
      ..placeholder,
      inputs: [supplyIn, oracleIn, userIn],
      outputs: [supplyOut, oracleOut, userOut, loanOut],
      mint: loanTokenMint,
      reference_inputs: [configIn],
      withdrawals: withdraw0,
      extra_signatories: [owner],
    }

  and {
    oracle.oracle.spend(
      owner,
      configPolicy,
      Some(oracleDatumIn),
      oracleAction,
      oracleIn.output_reference,
      tx,
    )?,
    loan.loanMint.mint(configPolicy, mintAction, s.loan, tx)?,
    lend.lend.withdraw(configPolicy, s.oracle, redeemer, Script(#"bebe"), tx)?,
  }
}
