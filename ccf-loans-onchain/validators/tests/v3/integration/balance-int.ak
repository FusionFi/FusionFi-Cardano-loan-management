use cardano/address.{Script}
use cardano/assets
use cardano/transaction.{InlineDatum, Transaction, placeholder}
use ccfl/typesv3.{
  LoanDatum, MerkelConfigDatum, MerkelLoanAction, OracleAction, OracleDatum,
  OracleUpdate, WithdrawAction,
}
use tests/scripts as s
use tests/tools as t
use tests/v3 as v
use v3/balance
use v3/loan
use v3/oracle

//                         //
// Balance Validator Tests //
//                         //

test balance_single() {
  let owner = #"ffff"
  let inRatio = 1000
  let outRatio = 1000

  let inLoanAmount = 1000
  let inCollateralAmount = 2000
  let inCollateralValue = 2000

  let outLoanAmount = 1000
  let outCollateralAmount = 2000
  let outCollateralValue = 4000

  let configPolicy = s.config
  let loanHash = s.loan

  let test_owner = #"face"
  let configValue = assets.from_asset(configPolicy, "", 1)
  let oracleValue = assets.from_asset(s.oracle, #"beef", 1)

  // withdrawl
  let withdraw0 = v.withdrawal(s.balance)

  let bRedeemer = v.withdrawAction(0)

  let loanDatum = LoanDatum(1000, 1000, 0, 1111111111111, #"beef", #"cafe")

  let loanIn1 = v.loanInput(1, inLoanAmount)
  let colIn1 = v.collateralInput(1, inCollateralAmount, inCollateralValue)

  let userIn1 = v.userAdaInput(2024)
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

  let oracleOut = v.oracleOutput(outRatio)

  let loanOut1 = v.loanOutput(outLoanAmount)
  let colOut1 = v.collateralOutput(outCollateralAmount, outCollateralValue)

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

  let oracleAction = OracleUpdate(1000, 1111111111112, 1000000, 0)
  let loanAction = MerkelLoanAction(0)

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [colIn1, loanIn1, oracleIn, userIn1],
      outputs: [colOut1, loanOut1, oracleOut],
      withdrawals: withdraw0,
      extra_signatories: [owner],
    }

  and {
    balance.balance.withdraw(
      s.oracle,
      s.config,
      bRedeemer,
      Script(s.balance),
      tx,
    )?,
    oracle.oracle.spend(
      owner,
      configPolicy,
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
