use aiken/builtin.{if_then_else}
use cardano/address.{Script}
use cardano/assets
use cardano/transaction.{InlineDatum, Transaction, placeholder}
use ccfl/interestcalcs.{interestPayment, interestSlope1, interestSlope2}
use tests/scripts as s
use tests/tools as t
use tests/v3 as v
use v3/repay

//                       //
// Repay Validator Tests //
//                       //

test repay() {
  let inRatio = 500
  let outRatio = 500

  let inLoanAmount = 100
  let inCollateralAmount = 200
  let inCollateralValue = 400

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

  let inTimestamp = 1111111111111
  let outTimestamp = 1111211111111

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
  let withdraw0 = v.withdrawal(t.merkelRepay)

  let bRedeemer = v.withdrawAction(0)

  let loanIn1 = v.loanTimestampInput(1, inLoanAmount, inTimestamp)
  let colIn1 = v.collateralInput(1, inCollateralAmount, inCollateralValue)

  let userIn1 = v.userAdaInput(2000000)
  let configIn = v.configInput()
  let interestIn = v.interestInput()
  let oracleIn = v.oracleTimestampInput(inRatio, inTimestamp)
  let oracleOut = v.oracleTimestampOutput(outRatio, outTimestamp)

  let loanOut1 = v.loanTimestampOutput(outLoanAmount, outTimestamp)
  let colOut1 = v.collateralOutput(outCollateralAmount, outCollateralValue)
  let interestOut =
    t.test_output(
      t.test_address(interestAddr),
      t.makeAdaValue(interestPayment),
      InlineDatum(#"cafe"),
    )

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn, interestIn],
      extra_signatories: [test_owner],
      inputs: [colIn1, loanIn1, oracleIn, userIn1],
      outputs: [colOut1, loanOut1, oracleOut, interestOut],
      withdrawals: withdraw0,
    }

  repay.repay.withdraw(
    interestAddr,
    s.oracle,
    s.config,
    bRedeemer,
    Script(s.repay),
    tx,
  )?
}
