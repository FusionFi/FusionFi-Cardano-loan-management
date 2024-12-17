use cardano/address.{Script}
use cardano/assets
use cardano/transaction.{Transaction, placeholder}
use ccfl/typesv3.{WithdrawAction}
use tests/scripts as s
use tests/tools as t
use tests/v3 as tx
use v3/balance

//                         //
// Balance Validator Tests //
//                         //

test balance_single() {
  let inRatio = 1000
  let outRatio = 1000

  let inLoanAmount = 1000
  let inCollateralAmount = 2000
  let inCollateralValue = 2000

  let outLoanAmount = 1000
  let outCollateralAmount = 2000
  let outCollateralValue = 4000

  let test_owner = #"face"

  // withdrawl
  let withdraw0 = tx.withdrawal(s.balance)

  let bRedeemer = tx.withdrawAction(0)

  let loanIn1 = tx.loanInput(1, inLoanAmount)
  let colIn1 = tx.collateralInput(1, inCollateralAmount, inCollateralValue)

  let userIn1 = tx.userAdaInput(2024)
  let configIn = tx.configInput()
  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let loanOut1 = tx.loanOutput(outLoanAmount)
  let colOut1 = tx.collateralOutput(outCollateralAmount, outCollateralValue)

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [colIn1, loanIn1, oracleIn, userIn1],
      outputs: [colOut1, loanOut1, oracleOut],
      withdrawals: withdraw0,
    }

  balance.balance.withdraw(s.oracle, s.config, bRedeemer, Script(s.balance), tx)?
}
