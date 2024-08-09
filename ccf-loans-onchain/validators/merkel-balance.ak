use aiken/list
use aiken/transaction.{
  InlineDatum, Input, Output, ScriptContext, Transaction, WithdrawFrom,
  placeholder,
}
// use aiken/transaction/credential
use aiken/transaction/value.{PolicyId}
use ccfl/helpers.{merkelTx}
use ccfl/types.{
  CollateralDatum, LoanDatum, MerkelConfigDatum, OracleDatum, WithdrawRedeemer,
}
use tests/tools as t
use tests/transactions as tx

// staking validators that check the full transaction scope.

// Merkel Balance validates the whole transaction for the Balance redeemer case
// it combines both the merkel-loan && merkel-collateral cases together

validator(p: PolicyId, cp: PolicyId) {
  fn balance(r: WithdrawRedeemer, c: ScriptContext) {
    // True
    expect ScriptContext {
      transaction,
      purpose: WithdrawFrom(_stake_credential),
    } = c

    let Transaction { inputs, outputs, reference_inputs, .. } = transaction

    expect Some(oracleOut) =
      list.find(
        outputs,
        fn(output) { list.has(value.policies(output.value), p) },
      )

    expect InlineDatum(datum) = oracleOut.datum
    expect rDatum: OracleDatum = datum

    let exchangeRate = rDatum.exchange

    expect Some(configIn) =
      list.find(
        reference_inputs,
        fn(input) { list.has(value.policies(input.output.value), cp) },
      )

    expect InlineDatum(datum) = configIn.output.datum
    expect _cDatum: MerkelConfigDatum = datum

    merkelTx(
      fn(collateral, loan) {
        let loanToken = value.without_lovelace(loan.value)
        expect InlineDatum(datum) = collateral.datum
        expect _colDatum: CollateralDatum = datum
        expect InlineDatum(datum) = loan.datum
        expect loanDatum: LoanDatum = datum
        expect Some(loanIn) =
          list.find(
            inputs,
            fn(in) {
              in.output.address.payment_credential == loan.address.payment_credential && value.without_lovelace(
                in.output.value,
              ) == loanToken
            },
          )
        expect InlineDatum(datum) = loanIn.output.datum
        expect lin: LoanDatum = datum
        expect Some(colIn) =
          list.find(
            inputs,
            fn(in) {
              in.output.address.payment_credential == collateral.address.payment_credential && value.without_lovelace(
                in.output.value,
              ) == loanToken
            },
          )
        expect InlineDatum(datum) = colIn.output.datum
        expect _cin: CollateralDatum = datum

        let adaOut = value.lovelace_of(collateral.value) / 1000000
        let exchangeAdjustment = loanDatum.amount * 1000
        let expectedCollateral = exchangeAdjustment / exchangeRate
        let minCollateralValue = expectedCollateral * 2
        let expectedOracle = value.from_asset(p, loanDatum.oracle, 1)

        adaOut >= minCollateralValue && value.without_lovelace(oracleOut.value) == expectedOracle && loanDatum.amount == lin.amount
      },
      r.a,
      outputs,
    )
  }
}

//                 //
// Validator Tests //
//                 //

test merkel_balance_single() {
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
  let withdraw0 = tx.withdrawal(t.merkelBalance)

  let bRedeemer = tx.withdrawRedeemer([0])

  let loanIn1 = tx.mLoanInput(1, inLoanAmount)
  let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue)

  let userIn1 = tx.userInput(2024)
  let configIn = tx.configInput()
  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let loanOut1 = tx.mLoanOutput(outLoanAmount)
  let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue)

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [colIn1, loanIn1, oracleIn, userIn1],
      outputs: [colOut1, loanOut1, oracleOut],
      withdrawals: withdraw0,
    }

  let ctx1 = tx.wCtx(t.merkelBalance, tx)

  balance(t.oracleMintHash, t.configMintHash, bRedeemer, ctx1)?
}
// test separate_balance_single() {
//   let inRatio = 2
//   let outRatio = 2

//   let inLoanAmount = 1000
//   let inCollateralAmount = 1000
//   let inCollateralValue = 2000

//   let outLoanAmount = 1000
//   let outCollateralAmount = 1000
//   let outCollateralValue = 2000

//   let test_owner = #"face"

//   let withdraw0 = tx.withdrawal(t.merkelCollateralBalance)

//   let loanIn1 = tx.loanInput(1, inLoanAmount)
//   let colIn1 = tx.collateralInput(1, inCollateralAmount, inCollateralValue)

//   let userIn1 = tx.userInput(2024)

//   let configIn = tx.configInput()
//   let oracleIn = tx.oracleInput(inRatio)
//   let oracleOut = tx.oracleOutput(outRatio)

//   let loanOut1 = tx.loanOutput(outLoanAmount)
//   let colOut1 = tx.collateralOutput(outCollateralAmount, outCollateralValue)

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       extra_signatories: [test_owner],
//       inputs: [colIn1, loanIn1, oracleIn, userIn1],
//       outputs: [colOut1, loanOut1, oracleOut],
//       withdrawals: withdraw0,
//     }

//   let colRedeemer =
//     [(0, 0)]

//   let loanRedeemer =
//     [(1, 1)]

//   let ctx1 = tx.wCtx(t.merkelCollateralBalance, tx)

//   let ctx2 = tx.wCtx(t.merkelLoanBalance, tx)

//   colBalance(
//     t.merkelCollateralSpend,
//     t.loanMintHash,
//     t.oracleMintHash,
//     t.configMintHash,
//     colRedeemer,
//     ctx1,
//   )? && loanBalance(
//     t.merkelLoanSpend,
//     t.loanMintHash,
//     t.oracleMintHash,
//     t.configMintHash,
//     loanRedeemer,
//     ctx2,
//   )?
// }

// test merkel_balance_multi() {
//   let inRatio = 2
//   let outRatio = 2

//   let inLoanAmount = 1000
//   let inCollateralAmount = 1000
//   let inCollateralValue = 2000

//   let outLoanAmount = 1000
//   let outCollateralAmount = 1000
//   let outCollateralValue = 2000

//   let test_owner = #"face"

//   let withdraw0 = tx.withdrawal(t.merkelBalance)

//   let loanIn1 = tx.mLoanInput(1, inLoanAmount)
//   let loanIn2 = tx.mLoanInput(2, inLoanAmount)
//   let loanIn3 = tx.mLoanInput(3, inLoanAmount)

//   let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue)
//   let colIn2 = tx.mCollateralInput(2, inCollateralAmount, inCollateralValue)
//   let colIn3 = tx.mCollateralInput(3, inCollateralAmount, inCollateralValue)

//   let userIn1 = tx.userInput(2024)

//   let configIn = tx.configInput()

//   let oracleIn = tx.oracleInput(inRatio)
//   let oracleOut = tx.oracleOutput(outRatio)

//   let loanOut1 = tx.mLoanOutput(outLoanAmount)
//   let loanOut2 = tx.mLoanOutput(outLoanAmount)
//   let loanOut3 = tx.mLoanOutput(outLoanAmount)

//   let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue)
//   let colOut2 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue)
//   let colOut3 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue)

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       extra_signatories: [test_owner],
//       inputs: [
//         loanIn1,
//         loanIn2,
//         loanIn3,
//         oracleIn,
//         userIn1,
//         colIn1,
//         colIn2,
//         colIn3,
//       ],
//       outputs: [
//         loanOut1,
//         loanOut2,
//         loanOut3,
//         oracleOut,
//         colOut1,
//         colOut2,
//         colOut3,
//       ],
//       withdrawals: withdraw0,
//     }

//   let bRedeemer =
//     [(0, 4), (1, 5), (2, 6)]

//   let ctx1 = tx.wCtx(t.merkelBalance, tx)

//   balance(t.oracleMintHash, t.configMintHash, bRedeemer, ctx1)?
// }

// test separate_balance_multi() {
//   let inRatio = 2
//   let outRatio = 2

//   let inLoanAmount = 1000
//   let inCollateralAmount = 1000
//   let inCollateralValue = 2000

//   let outLoanAmount = 1000
//   let outCollateralAmount = 1000
//   let outCollateralValue = 2000

//   let test_owner = #"face"

//   // let configDatum = tx.configDatumIn()
//   let withdraw0 = tx.withdrawal(t.merkelBalance)

//   let loanIn1 = tx.loanInput(1, inLoanAmount)
//   let loanIn2 = tx.loanInput(2, inLoanAmount)
//   let loanIn3 = tx.loanInput(3, inLoanAmount)

//   let colIn1 = tx.collateralInput(1, inCollateralAmount, inCollateralValue)
//   let colIn2 = tx.collateralInput(2, inCollateralAmount, inCollateralValue)
//   let colIn3 = tx.collateralInput(3, inCollateralAmount, inCollateralValue)

//   let userIn1 = tx.userInput(2024)

//   let configIn = tx.configInput()

//   let oracleIn = tx.oracleInput(inRatio)
//   let oracleOut = tx.oracleOutput(outRatio)

//   let loanOut1 = tx.loanOutput(outLoanAmount)
//   let loanOut2 = tx.loanOutput(outLoanAmount)
//   let loanOut3 = tx.loanOutput(outLoanAmount)

//   let colOut1 = tx.collateralOutput(outCollateralAmount, outCollateralValue)
//   let colOut2 = tx.collateralOutput(outCollateralAmount, outCollateralValue)
//   let colOut3 = tx.collateralOutput(outCollateralAmount, outCollateralValue)

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       extra_signatories: [test_owner],
//       inputs: [
//         loanIn1,
//         loanIn2,
//         loanIn3,
//         oracleIn,
//         userIn1,
//         colIn1,
//         colIn2,
//         colIn3,
//       ],
//       outputs: [
//         loanOut1,
//         loanOut2,
//         loanOut3,
//         oracleOut,
//         colOut1,
//         colOut2,
//         colOut3,
//       ],
//       withdrawals: withdraw0,
//     }

//   let colRedeemer =
//     [(5, 4), (6, 5), (7, 6)]

//   let loanRedeemer =
//     [(0, 0), (1, 1), (2, 2)]

//   let ctx1 = tx.wCtx(t.merkelCollateralBalance, tx)

//   let ctx2 = tx.wCtx(t.merkelLoanBalance, tx)

//   colBalance(
//     t.merkelCollateralSpend,
//     t.loanMintHash,
//     t.oracleMintHash,
//     t.configMintHash,
//     colRedeemer,
//     ctx1,
//   )? && loanBalance(
//     t.merkelLoanSpend,
//     t.loanMintHash,
//     t.oracleMintHash,
//     t.configMintHash,
//     loanRedeemer,
//     ctx2,
//   )?
// }

// test collateral_amount_fail() fail {
//   let inRatio = 2
//   let outRatio = 2

//   let inLoanAmount = 1000
//   let inCollateralAmount = 1000
//   let inCollateralValue = 2000

//   let outLoanAmount = 1000
//   let outCollateralAmount = 1000
//   let outCollateralValue = 1000

//   let test_owner = #"face"

//   // withdrawl
//   let withdraw0 = tx.withdrawal(t.merkelBalance)

//   let bRedeemer =
//     [(1, 0)]

//   let loanIn1 = tx.mLoanInput(1, inLoanAmount)

//   let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue)

//   let userIn1 = tx.userInput(2024)

//   let configIn = tx.configInput()

//   let oracleIn = tx.oracleInput(inRatio)

//   let oracleOut = tx.oracleOutput(outRatio)

//   let loanOut1 = tx.mLoanOutput(outLoanAmount)

//   let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue)

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       extra_signatories: [test_owner],
//       inputs: [colIn1, loanIn1, oracleIn, userIn1],
//       outputs: [colOut1, loanOut1, oracleOut],
//       withdrawals: withdraw0,
//     }

//   let ctx1 = tx.wCtx(t.merkelBalance, tx)

//   balance(t.oracleMintHash, t.configMintHash, bRedeemer, ctx1)?
// }

// test collateral_balance_fail() fail {
//   let inRatio = 2
//   let outRatio = 2

//   let inLoanAmount = 1000
//   let inCollateralAmount = 1000
//   let inCollateralValue = 2000

//   let outLoanAmount = 1000
//   let outCollateralAmount = 500
//   let outCollateralValue = 2000

//   let test_owner = #"face"

//   // withdrawl
//   let withdraw0 = tx.withdrawal(t.merkelBalance)

//   let bRedeemer =
//     [(1, 0)]

//   let loanIn1 = tx.mLoanInput(1, inLoanAmount)
//   let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue)
//   let userIn1 = tx.userInput(2024)
//   let configIn = tx.configInput()
//   let oracleIn = tx.oracleInput(inRatio)

//   let oracleOut = tx.oracleOutput(outRatio)
//   let loanOut1 = tx.mLoanOutput(outLoanAmount)
//   let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue)

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       extra_signatories: [test_owner],
//       inputs: [colIn1, loanIn1, oracleIn, userIn1],
//       outputs: [colOut1, loanOut1, oracleOut],
//       withdrawals: withdraw0,
//     }

//   let ctx1 = tx.wCtx(t.merkelBalance, tx)

//   balance(t.oracleMintHash, t.configMintHash, bRedeemer, ctx1)?
// }

// test collateral_token_fail() fail {
//   let inRatio = 2
//   let outRatio = 2

//   let inLoanAmount = 1000
//   let inCollateralAmount = 1000
//   let inCollateralValue = 2000

//   let outLoanAmount = 1000
//   let outCollateralAmount = 1000
//   let outCollateralValue = 1000

//   let test_owner = #"face"

//   // withdrawl
//   let withdraw0 = tx.withdrawal(t.merkelBalance)

//   let bRedeemer =
//     [(1, 0)]

//   let loanIn1 = tx.mLoanInput(1, inLoanAmount)

//   let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue)

//   let userIn1 = tx.userInput(2024)

//   let configIn = tx.configInput()

//   let oracleIn = tx.oracleInput(inRatio)

//   let oracleOut = tx.oracleOutput(outRatio)

//   let loanOut1 = tx.mLoanOutput(outLoanAmount)

//   let colOut1 = tx.collateralOutput(outCollateralAmount, outCollateralValue)

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       extra_signatories: [test_owner],
//       inputs: [colIn1, loanIn1, oracleIn, userIn1],
//       outputs: [colOut1, loanOut1, oracleOut],
//       withdrawals: withdraw0,
//     }

//   let ctx1 = tx.wCtx(t.merkelBalance, tx)

//   balance(t.oracleMintHash, t.configMintHash, bRedeemer, ctx1)?
// }

// test loan_amount_fail() fail {
//   let inRatio = 2
//   let outRatio = 2

//   let inLoanAmount = 1000
//   let inCollateralAmount = 1000
//   let inCollateralValue = 2000

//   let outLoanAmount = 500
//   let outCollateralAmount = 1000
//   let outCollateralValue = 2000

//   let test_owner = #"face"

//   // withdrawl
//   let withdraw0 = tx.withdrawal(t.merkelBalance)

//   let bRedeemer =
//     [(1, 0)]

//   let loanIn1 = tx.mLoanInput(1, inLoanAmount)

//   let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue)

//   let userIn1 = tx.userInput(2024)

//   let configIn = tx.configInput()

//   let oracleIn = tx.oracleInput(inRatio)

//   let oracleOut = tx.oracleOutput(outRatio)

//   let loanOut1 = tx.mLoanOutput(outLoanAmount)

//   let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue)

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       extra_signatories: [test_owner],
//       inputs: [colIn1, loanIn1, oracleIn, userIn1],
//       outputs: [colOut1, loanOut1, oracleOut],
//       withdrawals: withdraw0,
//     }

//   let ctx1 = tx.wCtx(t.merkelBalance, tx)

//   balance(t.oracleMintHash, t.configMintHash, bRedeemer, ctx1)?
// }

// test loan_token_fail() fail {
//   let inRatio = 2
//   let outRatio = 2
//   let fakeToken = value.from_asset(t.loanMintHash, #"deaf", 1)

//   let inLoanAmount = 1000
//   let inCollateralAmount = 1000
//   let inCollateralValue = 2000

//   // let outLoanAmount = 1000
//   let outCollateralAmount = 1000
//   let outCollateralValue = 2000

//   let test_owner = #"face"

//   // withdrawl
//   let withdraw0 = tx.withdrawal(t.merkelBalance)

//   let bRedeemer =
//     [(1, 0)]

//   let loanIn1 = tx.mLoanInput(1, inLoanAmount)

//   let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue)

//   let userIn1 = tx.userInput(2024)

//   let configIn = tx.configInput()

//   let oracleIn = tx.oracleInput(inRatio)

//   let oracleOut = tx.oracleOutput(outRatio)

//   let loanOut1 =
//     t.test_output(
//       t.test_script_address(t.mLoan),
//       value.merge(t.makeAdaValue(2), fakeToken),
//       tx.loanOutDatum(1000),
//     )

//   let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue)

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       extra_signatories: [test_owner],
//       inputs: [colIn1, loanIn1, oracleIn, userIn1],
//       outputs: [colOut1, loanOut1, oracleOut],
//       withdrawals: withdraw0,
//     }

//   let ctx1 = tx.wCtx(t.merkelBalance, tx)

//   balance(t.oracleMintHash, t.configMintHash, bRedeemer, ctx1)?
// }

// test oracle_out_fail() fail {
//   let inRatio = 2
//   let outRatio = 1

//   let inLoanAmount = 1000
//   let inCollateralAmount = 1000
//   let inCollateralValue = 2000

//   let outLoanAmount = 1000
//   let outCollateralAmount = 1000
//   let outCollateralValue = 2000

//   let test_owner = #"face"

//   // withdrawl
//   let withdraw0 = tx.withdrawal(t.merkelBalance)

//   let bRedeemer =
//     [(1, 0)]

//   let loanIn1 = tx.mLoanInput(1, inLoanAmount)

//   let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue)

//   let userIn1 = tx.userInput(2024)

//   let configIn = tx.configInput()

//   let oracleIn = tx.oracleInput(inRatio)

//   let oracleOut = tx.oracleOutput(outRatio)

//   let loanOut1 = tx.mLoanOutput(outLoanAmount)

//   let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue)

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       extra_signatories: [test_owner],
//       inputs: [colIn1, loanIn1, oracleIn, userIn1],
//       outputs: [colOut1, loanOut1, oracleOut],
//       withdrawals: withdraw0,
//     }

//   let ctx1 = tx.wCtx(t.merkelBalance, tx)

//   balance(t.oracleMintHash, t.configMintHash, bRedeemer, ctx1)?
// }

// test oracle_token_fail() fail {
//   let inRatio = 2
//   let outRatio = 2

//   let inLoanAmount = 1000
//   let inCollateralAmount = 1000
//   let inCollateralValue = 2000

//   let outLoanAmount = 1000
//   let outCollateralAmount = 1000
//   let outCollateralValue = 2000

//   let test_owner = #"face"

//   // withdrawl
//   let withdraw0 = tx.withdrawal(t.merkelBalance)

//   let bRedeemer =
//     [(1, 0)]

//   let loanIn1 = tx.mLoanInput(1, inLoanAmount)

//   let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue)

//   let userIn1 = tx.userInput(2024)

//   let configIn = tx.configInput()

//   let oracleIn = tx.oracleInput(inRatio)

//   let oracleOut = tx.collateralOutput(outRatio, 15)

//   let loanOut1 = tx.mLoanOutput(outLoanAmount)

//   let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue)

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       extra_signatories: [test_owner],
//       inputs: [colIn1, loanIn1, oracleIn, userIn1],
//       outputs: [colOut1, loanOut1, oracleOut],
//       withdrawals: withdraw0,
//     }

//   let ctx1 = tx.wCtx(t.merkelBalance, tx)

//   balance(t.oracleMintHash, t.configMintHash, bRedeemer, ctx1)?
// }

// test config_token_fail() fail {
//   let inRatio = 2
//   let outRatio = 2

//   let inLoanAmount = 1000
//   let inCollateralAmount = 1000
//   let inCollateralValue = 2000

//   let outLoanAmount = 1000
//   let outCollateralAmount = 1000
//   let outCollateralValue = 2000

//   let test_owner = #"face"

//   // withdrawl
//   let withdraw0 = tx.withdrawal(t.merkelBalance)

//   let bRedeemer =
//     [(1, 0)]

//   let loanIn1 = tx.mLoanInput(1, inLoanAmount)

//   let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue)

//   let userIn1 = tx.userInput(2024)

//   let configIn = tx.oracleInput(inRatio)

//   let oracleIn = tx.oracleInput(inRatio)

//   let oracleOut = tx.oracleOutput(outRatio)

//   let loanOut1 = tx.mLoanOutput(outLoanAmount)

//   let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue)

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       extra_signatories: [test_owner],
//       inputs: [colIn1, loanIn1, oracleIn, userIn1],
//       outputs: [colOut1, loanOut1, oracleOut],
//       withdrawals: withdraw0,
//     }

//   let ctx1 = tx.wCtx(t.merkelBalance, tx)

//   balance(t.oracleMintHash, t.configMintHash, bRedeemer, ctx1)?
// }

// test config_datum_fail() fail {
//   let inRatio = 2
//   let outRatio = 2

//   let inLoanAmount = 1000
//   let inCollateralAmount = 1000
//   let inCollateralValue = 2000

//   let outLoanAmount = 1000
//   let outCollateralAmount = 1000
//   let outCollateralValue = 2000

//   let test_owner = #"face"

//   // withdrawl
//   let withdraw0 = tx.withdrawal(t.merkelBalance)

//   let bRedeemer =
//     [(1, 0)]

//   let loanIn1 = tx.mLoanInput(1, inLoanAmount)

//   let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue)

//   let userIn1 = tx.userInput(2024)

//   let configIn = tx.oracleInput(inRatio)

//   let oracleIn = tx.oracleInput(inRatio)

//   let oracleOut = tx.oracleOutput(outRatio)

//   let loanOut1 = tx.mLoanOutput(outLoanAmount)

//   let colOut1 = tx.mCollateralOutput(outCollateralAmount, outCollateralValue)

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       extra_signatories: [test_owner],
//       inputs: [colIn1, loanIn1, oracleIn, userIn1],
//       outputs: [colOut1, loanOut1, oracleOut],
//       withdrawals: withdraw0,
//     }

//   let ctx1 = tx.wCtx(t.merkelBalance, tx)

//   balance(t.oracleMintHash, t.configMintHash, bRedeemer, ctx1)?
// }

// // Merkel Loan && Collateral for comparison tests //

// validator(colVal: ScriptHash, lp: PolicyId, op: PolicyId, cp: PolicyId) {
//   fn colBalance(r: List<(Int, Int)>, c: ScriptContext) {
//     expect ScriptContext { transaction, purpose: WithdrawFrom(stake_cred) } = c

//     let Transaction { outputs, reference_inputs, .. } = transaction

//     expect Inline(ScriptCredential(_own_validator)) = stake_cred

//     expect Some(oracleOut) =
//       list.find(
//         outputs,
//         fn(output) { list.has(value.policies(output.value), op) },
//       )

//     expect InlineDatum(datum) = oracleOut.datum
//     expect rDatum: OracleDatum = datum

//     let exchangeRate = rDatum.usdAda

//     expect Some(configIn) =
//       list.find(
//         reference_inputs,
//         fn(input) { list.has(value.policies(input.output.value), cp) },
//       )

//     expect InlineDatum(datum) = configIn.output.datum
//     expect cDatum: MerkelConfigDatum = datum

//     withdraw4(
//       fn(input, output) {
//         expect Some(collateralToken) =
//           list.head(value.flatten(value.without_lovelace(input.value)))

//         expect Some(loanOut) =
//           list.find(
//             outputs,
//             fn(output) {
//               expect Some(loanToken) =
//                 list.head(value.flatten(value.without_lovelace(output.value)))

//               output.address.payment_credential == ScriptCredential(
//                 cDatum.loanVal,
//               ) && loanToken == collateralToken
//             },
//           )

//         expect InlineDatum(datum) = loanOut.datum
//         expect lDatum: LoanDatum = datum

//         let adaOut = value.lovelace_of(output.value) / 1000000

//         let minCollateralValue = lDatum.amount * exchangeRate * ( 50 / 100 )

//         expect list.has(value.policies(output.value), lp)

//         expect InlineDatum(datum) = output.datum
//         expect outDatum: CollateralDatum = datum

//         input.address.payment_credential == output.address.payment_credential && adaOut >= minCollateralValue && outDatum.amount == value.lovelace_of(
//           output.value,
//         ) / exchangeRate / 1000000 && list.has(
//           value.flatten(output.value),
//           collateralToken,
//         )
//       },
//       colVal,
//       r,
//       transaction,
//     )
//   }
// }

// validator(loanVal: ScriptHash, lp: PolicyId, op: PolicyId, cp: PolicyId) {
//   fn loanBalance(r: List<(Int, Int)>, c: ScriptContext) {
//     expect ScriptContext { transaction, purpose: WithdrawFrom(stake_cred) } = c

//     let Transaction { outputs, reference_inputs, .. } = transaction

//     expect Inline(ScriptCredential(own_validator)) = stake_cred

//     expect Some(oracleOut) =
//       list.find(
//         outputs,
//         fn(output) { list.has(value.policies(output.value), op) },
//       )

//     expect InlineDatum(datum) = oracleOut.datum
//     expect rDatum: OracleDatum = datum

//     let exchangeRate = rDatum.usdAda

//     expect Some(configIn) =
//       list.find(
//         reference_inputs,
//         fn(input) { list.has(value.policies(input.output.value), cp) },
//       )

//     expect InlineDatum(datum) = configIn.output.datum
//     expect cDatum: MerkelConfigDatum = datum

//     withdraw4(
//       fn(input, output) {
//         expect InlineDatum(datum) = input.datum
//         expect d: LoanDatum = datum

//         expect Some(loanToken) =
//           list.head(value.flatten(value.without_lovelace(input.value)))

//         expect Some(colOut) =
//           list.find(
//             outputs,
//             fn(output) {
//               expect Some(colToken) =
//                 list.head(value.flatten(value.without_lovelace(output.value)))

//               output.address.payment_credential == ScriptCredential(
//                 cDatum.colVal,
//               ) && loanToken == colToken
//             },
//           )

//         expect InlineDatum(datum) = colOut.datum
//         expect colDatum: CollateralDatum = datum

//         let adaOut = value.lovelace_of(colOut.value) / 1000000

//         // let newCollateralValue = adaOut / exchangeRate
//         let minCollateralValue = d.amount * exchangeRate * ( 50 / 100 )

//         expect list.has(value.policies(output.value), lp)

//         expect InlineDatum(datum) = output.datum
//         expect datum: LoanDatum = datum

//         input.address.payment_credential == output.address.payment_credential && datum.amount == d.amount && datum.interest == d.interest && datum.term == d.term && adaOut >= minCollateralValue
//       },
//       loanVal,
//       r,
//       transaction,
//     )
//   }
// }
