use cardano/address.{Script}
use cardano/assets
use cardano/transaction.{Transaction, placeholder}
use tests/prop
use tests/tools as t
use tests/transactions as tx
use v1/merkel_balance

//                         //
// Balance Validator Tests //
//                         //

test merkel_balance_single((a, b, c, d) via prop.fourInts()) fail {
  let inRatio = 1000
  let outRatio = 1000

  let inLoanAmount = a
  let inCollateralAmount = b
  let inCollateralValue = b

  let outLoanAmount = c
  let outCollateralAmount = d
  let outCollateralValue = d

  let test_owner = #"face"

  // withdrawl
  let withdraw0 = tx.withdrawal(t.merkelBalance)

  let bRedeemer = tx.withdrawRedeemer([0])

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
      inputs: [colIn1, loanIn1, oracleIn, userIn1],
      outputs: [colOut1, loanOut1, oracleOut],
      withdrawals: withdraw0,
    }

  merkel_balance.balance.withdraw(
    t.oracleMintHash,
    t.configMintHash,
    bRedeemer,
    Script(t.merkelBalance),
    tx,
  )?
}
