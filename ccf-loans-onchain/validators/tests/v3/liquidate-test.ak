use cardano/address.{Script}
use cardano/assets
use cardano/transaction.{Transaction, placeholder}
use tests/scripts as s
use tests/tools as t
use tests/v3 as v
use v3/liquidate

//                             //
// Liquidation Validator Tests //
//                             //

test liquidate() {
  let inRatio = 200
  let outRatio = 200

  let inLoanAmount = 1000
  let inCollateralAmount = 2000
  let inCollateralValue = 4000

  let outLoanAmount = 0
  let outCollateralAmount = 0
  let outCollateralValue = 2

  let test_owner = #"face"

  // withdrawl
  let withdraw0 = v.withdrawal(t.merkelLiquidate)

  let loanIn1 = v.loanInput(1, inLoanAmount)
  let colIn1 = v.collateralInput(1, inCollateralAmount, inCollateralValue)

  let userIn1 = v.userAdaInput(2024)

  let configIn = v.configInput()
  let oracleIn = v.oracleInput(inRatio)
  let oracleOut = v.oracleOutput(outRatio)

  let loanOut1 = v.loanOutput(outLoanAmount)
  let colOut1 = v.collateralOutput(outCollateralAmount, outCollateralValue)

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [loanIn1, oracleIn, userIn1, colIn1],
      outputs: [loanOut1, oracleOut, colOut1],
      withdrawals: withdraw0,
    }

  let redeemerList = v.withdrawAction(2)

  liquidate.liquidate.withdraw(
    s.oracle,
    s.config,
    redeemerList,
    Script(s.liquidate),
    tx,
  )?
}
