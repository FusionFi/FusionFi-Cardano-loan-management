use aiken/builtin.{if_then_else}
use cardano/address.{VerificationKey}
use cardano/assets
use cardano/transaction.{Transaction, placeholder}
use ccfl/interestcalcs.{interestPayment, interestSlope1, interestSlope2}
use ori/merkel_repay
use tests/prop
use tests/tools as t
use tests/transactions as tx

//                       //
// Repay Validator Tests //
//                       //

test repayFail((t, a) via prop.loanTime()) fail {
  let inRatio = 1000
  let outRatio = 1000

  let inLoanAmount = 1000
  let inCollateralAmount = 2000
  let inCollateralValue = 4000

  let outLoanAmount = 0
  let outCollateralAmount = 0
  let outCollateralValue = 2

  let base = 55
  let optimal = 70
  let slope1 = 40
  let slope2 = 300
  let supply = 1000000
  let borrowed = 200000
  let utilisation = 1000000 / 200000

  let test_owner = #"face"
  let interestAddr = #"deaf"

  let inTimestamp = 1111111111
  let outTimestamp = t + 1111111111

  let timeframe = outTimestamp - inTimestamp

  let interest =
    if_then_else(
      utilisation <= optimal,
      interestSlope1(base, optimal, slope1, supply, borrowed),
      interestSlope2(base, optimal, slope1, slope2, supply, borrowed),
    )

  let interestPayment = interestPayment(timeframe, inLoanAmount, interest)

  let interestExchange = interestPayment / outRatio

  // withdrawl
  let withdraw0 = tx.withdrawal(t.merkelRepay)

  let bRedeemer = tx.withdrawRedeemer([0])

  let loanIn1 = tx.mLoanInput(1, inLoanAmount)
  let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue, 0)

  let userIn1 = tx.userInput(2000000)
  let configIn = tx.configInput()
  let interestIn = tx.interestInput()
  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let loanOut1 = tx.mLoanOutput(outLoanAmount)
  let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue, 0)
  let interestOut = tx.interestOutput(a * 1000000)

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn, interestIn],
      extra_signatories: [test_owner],
      inputs: [colIn1, loanIn1, oracleIn, userIn1],
      outputs: [colOut1, loanOut1, oracleOut, interestOut],
      withdrawals: withdraw0,
    }

  merkel_repay.repay.withdraw(
    interestAddr,
    t.oracleMintHash,
    t.configMintHash,
    bRedeemer,
    VerificationKey(t.merkelRepay),
    tx,
  )
}
