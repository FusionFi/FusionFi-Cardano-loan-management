use cardano/address.{Script}
use cardano/assets
use cardano/transaction.{InlineDatum, Transaction, placeholder}
use ccfl/typesv3.{
  LoanDatum, MerkelConfigDatum, MerkelLoanAction, OracleDatum, OracleUpdate,
}
use tests/scripts as s
use tests/tools as t
use tests/v3 as v
use v3/liquidate
use v3/loan
use v3/oracle

//                             //
// Liquidation Validator Tests //
//                             //

test liquidate() {
  let owner = #"ffff"

  let inRatio = 200
  let outRatio = 200

  let inLoanAmount = 1000
  let inCollateralAmount = 2000
  let inCollateralValue = 4000

  let outLoanAmount = 0
  let outCollateralAmount = 0
  let outCollateralValue = 2

  let configPolicy = s.config
  let configValue = assets.from_asset(configPolicy, "", 1)

  let loanHash = s.loan

  let test_owner = #"face"

  // withdrawl
  let withdraw0 = v.withdrawal(s.liquidate)

  let loanIn1 = v.loanInput(1, inLoanAmount)
  let colIn1 = v.collateralInput(1, inCollateralAmount, inCollateralValue)

  let userIn1 = v.userAdaInput(2024)

  let configDatum =
    MerkelConfigDatum {
      loanVal: loanHash,
      colVal: s.collateral,
      oracleVal: s.oracle,
      interestVal: s.interest,
      supplyVal: s.pool,
      collateralRedeemers: [s.balance, s.liquidate, s.repay, s.close],
      supplyRedeemers: [s.supply, s.lend, s.withdraw, s.closePool],
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
  let oracleIn = v.oracleInput(inRatio)
  let oracleOut = v.oracleOutput(outRatio)
  let loanDatum = LoanDatum(1000, 1000, 0, 1111111111111, #"beef", #"cafe")

  let loanOut1 = v.loanOutput(outLoanAmount)
  let colOut1 = v.collateralOutput(outCollateralAmount, outCollateralValue)

  let oracleAction = OracleUpdate(outRatio, 2222222222222, 1000000, 0)
  let oracleValue = assets.from_asset(s.oracle, #"beef", 1)
  let oracleOutDatum =
    v.oracleDatum(outRatio, 2222222222222, "USD", 1000000, 200000)

  let oracleOut =
    t.test_output(
      t.test_script_address(s.oracle),
      oracleValue,
      InlineDatum(oracleOutDatum),
    )
  let loanAction = MerkelLoanAction(1)

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [loanIn1, oracleIn, userIn1, colIn1],
      outputs: [loanOut1, oracleOut, colOut1],
      withdrawals: withdraw0,
      extra_signatories: [owner],
    }

  let redeemerList = v.withdrawAction(2)

  and {
    liquidate.liquidate.withdraw(
      s.oracle,
      s.config,
      redeemerList,
      Script(s.liquidate),
      tx,
    )?,
    oracle.oracle.spend(
      owner,
      s.config,
      Some(oracleDatumIn),
      oracleAction,
      oracleIn.output_reference,
      tx,
    )?,
    loan.loanMint.spend(
      configPolicy,
      Some(loanDatum),
      loanAction,
      loanIn1.output_reference,
      tx,
    )?,
  }
}
