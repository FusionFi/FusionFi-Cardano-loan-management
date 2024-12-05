use cardano/address.{Script}
use cardano/assets
use cardano/transaction.{Transaction, placeholder}
use tests/prop
use tests/tools as t
use tests/transactions as tx
use v1/merkel_liquidate

//                             //
// Liquidation Validator Tests //
//                             //

test liquidateFail((a, b, c, d) via prop.fourInts()) {
  let inRatio = a * 100
  let outRatio = a * 100

  let inLoanAmount = b * 1000
  let inCollateralAmount = b * 1000
  let inCollateralValue = c * 1000

  let outLoanAmount = 0
  let outCollateralAmount = 0
  let outCollateralValue = 2

  let test_owner = #"face"

  // withdrawl
  let withdraw0 = tx.withdrawal(t.merkelLiquidate)

  let loanIn1 = tx.mLoanInput(1, inLoanAmount)
  let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue, 0)

  let userIn1 = tx.userInput(2024)

  let configIn = tx.configInput()
  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let loanOut1 = tx.mLoanOutput(outLoanAmount)
  let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue, 0)

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [loanIn1, oracleIn, userIn1, colIn1],
      outputs: [loanOut1, oracleOut, colOut1],
      withdrawals: withdraw0,
    }

  let redeemerList = tx.withdrawRedeemer([2])

  merkel_liquidate.liquidate.withdraw(
    t.oracleMintHash,
    t.configMintHash,
    redeemerList,
    Script(t.merkelLiquidate),
    tx,
  )
}
