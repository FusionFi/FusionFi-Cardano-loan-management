use cardano/address.{Script}
use cardano/assets
use cardano/transaction.{NoDatum, Transaction, placeholder}
use ori/merkel_close
use tests/tools as t
use tests/transactions as tx

//                       //
// Close Validator Tests //
//                       //

test merkel_close_single() {
  let inRatio = 1000
  let outRatio = 1000

  let inLoanAmount = 0
  let inCollateralAmount = 0
  let inCollateralValue = 2

  let test_owner = #"face"

  // let configDatum = tx.configDatumIn()
  let withdraw0 = tx.withdrawal(t.merkelClose)

  let loanIn1 = tx.mLoanInput(1, inLoanAmount)
  let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue, 0)
  let userIn1 = tx.userInput(2024)

  let configIn = tx.configInput()

  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let redeemerList = tx.withdrawRedeemer([0])

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [loanIn1, oracleIn, userIn1, colIn1],
      outputs: [oracleOut],
      mint: t.loanBurnValue(),
      withdrawals: withdraw0,
    }

  merkel_close.close.withdraw(
    t.loanMintHash,
    t.oracleMintHash,
    redeemerList,
    Script(t.merkelClose),
    tx,
  )?
}
