use cardano/address.{Script}
use cardano/assets
use cardano/transaction.{NoDatum, Transaction, placeholder}
use tests/scripts as s
use tests/tools as t
use tests/v3 as v
use v3/close

//                       //
// Close Validator Tests //
//                       //

test close() {
  let inRatio = 1000
  let outRatio = 1000

  let inLoanAmount = 0
  let inCollateralAmount = 0
  let inCollateralValue = 2

  let test_owner = #"face"

  let loanBurnValue = assets.from_asset(s.loan, #"cafe", -2)

  // let configDatum = tx.configDatumIn()
  let withdraw0 = v.withdrawal(t.merkelClose)

  let loanIn1 = v.loanInput(1, inLoanAmount)
  let colIn1 = v.collateralInput(1, inCollateralAmount, inCollateralValue)
  let userIn1 = v.userAdaInput(2024)

  let configIn = v.configInput()

  let oracleIn = v.oracleInput(inRatio)
  let oracleOut = v.oracleOutput(outRatio)

  let redeemerList = v.withdrawAction(0)

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [loanIn1, oracleIn, userIn1, colIn1],
      outputs: [oracleOut],
      mint: loanBurnValue,
      withdrawals: withdraw0,
    }

  close.close.withdraw(s.loan, s.oracle, redeemerList, Script(s.close), tx)?
}
