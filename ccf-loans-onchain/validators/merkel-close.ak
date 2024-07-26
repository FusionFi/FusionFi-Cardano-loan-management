use aiken/dict
use aiken/list
use aiken/transaction.{
  InlineDatum, NoDatum, Output, ScriptContext, Transaction, WithdrawFrom,
  placeholder,
}
use aiken/transaction/credential.{Inline, ScriptCredential}
use aiken/transaction/value.{PolicyId}
use ccfl/helpers.{merkelBurn, withBurn}
use ccfl/types.{CollateralDatum, LoanDatum, ScriptHash, WithdrawRedeemer}
use tests/tools as t
use tests/transactions as tx

//                        //
// Merkel Close Validator //
//                        //

validator(lp: PolicyId, op: PolicyId) {
  fn close(r: WithdrawRedeemer, c: ScriptContext) {
    expect ScriptContext {
      transaction,
      purpose: WithdrawFrom(stake_credential),
    } = c

    let Transaction { inputs, outputs, mint, .. } = transaction

    expect Inline(ScriptCredential(_own_validator)) = stake_credential

    expect Some(_oracleOut) =
      list.find(
        outputs,
        fn(output) { list.has(value.policies(output.value), op) },
      )

    merkelBurn(
      fn(loan, collateral) {
        expect InlineDatum(datum) = loan.datum
        expect ld: LoanDatum = datum
        expect InlineDatum(datum) = collateral.datum
        expect cd: CollateralDatum = datum
        let loanTokenValue = value.without_lovelace(loan.value)
        let colTokenValue = value.without_lovelace(collateral.value)
        expect [Pair(loanTn, 1)] =
          loanTokenValue
            |> value.tokens(lp)
            |> dict.to_pairs()
        expect Some(burnVal) =
          value.zero()
            |> value.add(lp, loanTn, -2)
            |> value.flatten()
            |> list.head()
        let burns =
          mint
            |> value.from_minted_value()
            |> value.flatten()
        expect list.has(burns, burnVal)
        ld.amount == 0 && cd.amount == 0 && loanTokenValue == colTokenValue
      },
      r.a,
      inputs,
    )
  }
}

//                 //
// Validator Tests //
//                 //

test merkel_close_single() {
  let inRatio = 2
  let outRatio = 2

  let inLoanAmount = 0
  let inCollateralAmount = 0
  let inCollateralValue = 2

  let test_owner = #"face"

  let configDatum = tx.configDatumIn()

  let withdraw0 = tx.withdrawal(t.merkelClose)

  let loanIn1 = tx.mLoanInput(1, inLoanAmount)
  let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue)
  let userIn1 = tx.userInput(2024)

  let configIn = tx.configInput()

  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let redeemerList = tx.withdrawRedeemer([3])

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [loanIn1, oracleIn, userIn1, colIn1],
      outputs: [oracleOut],
      mint: value.to_minted_value(t.loanBurnValue()),
      withdrawals: withdraw0,
    }

  let ctx5 = tx.wCtx(t.merkelClose, tx)

  close(t.loanMintHash, t.oracleMintHash, redeemerList, ctx5)?
}
// test separate_close_single() {
//   let inRatio = 2
//   let outRatio = 2

//   let inLoanAmount = 0
//   let inCollateralAmount = 0
//   let inCollateralValue = 2

//   let test_owner = #"face"

//   let configDatum = tx.configDatumIn()

//   let loanIn1 = tx.loanInput(1, inLoanAmount)

//   let colIn1 = tx.collateralInput(1, inCollateralAmount, inCollateralValue)
//   let userIn1 = tx.userInput(2024)

//   let configIn = tx.configInput()

//   let oracleIn = tx.oracleInput(inRatio)
//   let oracleOut = tx.oracleOutput(outRatio)

//   let withdraw0 =
//     dict.from_ascending_list(
//       [
//         (t.create_stake_credential(t.merkelLoanClose), 0),
//         (t.create_stake_credential(t.merkelCollateralClose), 0),
//       ],
//       t.stakeCompare,
//     )

//   let loanRedeemer =
//     [0]

//   let collateralRedeemer =
//     [3]

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       extra_signatories: [test_owner],
//       inputs: [loanIn1, oracleIn, userIn1, colIn1],
//       outputs: [oracleOut],
//       mint: value.to_minted_value(t.loanBurnValue()),
//       withdrawals: withdraw0,
//     }

//   let ctx1 = tx.wCtx(t.merkelLoanClose, tx)

//   let ctx2 = tx.wCtx(t.merkelCollateralClose, tx)

//   collateralClose(
//     t.merkelCollateralSpend,
//     t.loanMintHash,
//     t.oracleMintHash,
//     collateralRedeemer,
//     ctx2,
//   )? && loanClose(
//     t.merkelLoanSpend,
//     t.loanMintHash,
//     t.oracleMintHash,
//     loanRedeemer,
//     ctx1,
//   )?
// }

// test merkel_close_multi() {
//   let inRatio = 2
//   let outRatio = 2

//   let inLoanAmount = 0
//   let inCollateralAmount = 0
//   let inCollateralValue = 2

//   let test_owner = #"face"

//   // withdrawl
//   let withdraw0 = tx.withdrawal(t.merkelClose)

//   let loanIn1 = tx.mLoanInput(1, inLoanAmount)
//   let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue)

//   let loanIn2 = tx.mLoanInput(2, inLoanAmount)
//   let colIn2 = tx.mCollateralInput(2, inCollateralAmount, inCollateralValue)

//   let loanIn3 = tx.mLoanInput(3, inLoanAmount)
//   let colIn3 = tx.mCollateralInput(3, inCollateralAmount, inCollateralValue)

//   let userIn1 = tx.userInput(2024)

//   let configIn = tx.configInput()
//   let oracleIn = tx.oracleInput(inRatio)
//   let oracleOut = tx.oracleOutput(outRatio)

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
//       outputs: [oracleOut],
//       mint: value.to_minted_value(t.loanBurnValue()),
//       withdrawals: withdraw0,
//     }

//   let redeemerList =
//     [(0, 5), (1, 6), (2, 7)]

//   let ctx5 = tx.wCtx(t.merkelClose, tx)

//   close(t.loanMintHash, t.oracleMintHash, redeemerList, ctx5)?
// }

// test separate_close_multi() {
//   let inRatio = 2
//   let outRatio = 2

//   let inLoanAmount = 0
//   let inCollateralAmount = 0
//   let inCollateralValue = 2

//   let test_owner = #"face"

//   let loanIn1 = tx.loanInput(1, inLoanAmount)
//   let colIn1 = tx.collateralInput(1, inCollateralAmount, inCollateralValue)

//   let loanIn2 = tx.loanInput(2, inLoanAmount)
//   let colIn2 = tx.collateralInput(2, inCollateralAmount, inCollateralValue)

//   let loanIn3 = tx.loanInput(3, inLoanAmount)
//   let colIn3 = tx.collateralInput(3, inCollateralAmount, inCollateralValue)

//   let userIn1 = tx.userInput(2024)

//   let configIn = tx.configInput()
//   let oracleIn = tx.oracleInput(inRatio)
//   let oracleOut = tx.oracleOutput(outRatio)

//   let withdraw0 =
//     dict.from_ascending_list(
//       [
//         (t.create_stake_credential(t.merkelLoanClose), 0),
//         (t.create_stake_credential(t.merkelCollateralClose), 0),
//       ],
//       t.stakeCompare,
//     )

//   let loanRedeemer =
//     [0, 1, 2]

//   let collateralRedeemer =
//     [5, 6, 7]

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
//       outputs: [oracleOut],
//       mint: value.to_minted_value(t.loanBurnValue()),
//       withdrawals: withdraw0,
//     }

//   let ctx1 = tx.wCtx(t.merkelLoanClose, tx)

//   let ctx2 = tx.wCtx(t.merkelCollateralClose, tx)

//   collateralClose(
//     t.merkelCollateralSpend,
//     t.loanMintHash,
//     t.oracleMintHash,
//     collateralRedeemer,
//     ctx2,
//   )? && loanClose(
//     t.merkelLoanSpend,
//     t.loanMintHash,
//     t.oracleMintHash,
//     loanRedeemer,
//     ctx1,
//   )?
// }

// test collateral_amount_fail() fail {
//   let inRatio = 2
//   let outRatio = 2

//   let inLoanAmount = 0
//   let inCollateralAmount = 10
//   let inCollateralValue = 2

//   let test_owner = #"face"

//   let configDatum = tx.configDatumIn()

//   let withdraw0 = tx.withdrawal(t.merkelClose)

//   let loanIn1 = tx.mLoanInput(1, inLoanAmount)
//   let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue)
//   let userIn1 = tx.userInput(2024)

//   let configIn = tx.configInput()

//   let oracleIn = tx.oracleInput(inRatio)
//   let oracleOut = tx.oracleOutput(outRatio)

//   let redeemerList =
//     [(0, 3)]

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       extra_signatories: [test_owner],
//       inputs: [loanIn1, oracleIn, userIn1, colIn1],
//       outputs: [oracleOut],
//       mint: value.to_minted_value(t.loanBurnValue()),
//       withdrawals: withdraw0,
//     }

//   let ctx5 = tx.wCtx(t.merkelClose, tx)

//   close(t.loanMintHash, t.oracleMintHash, redeemerList, ctx5)?
// }

// test loan_amount_fail() fail {
//   let inRatio = 2
//   let outRatio = 2

//   let inLoanAmount = 10
//   let inCollateralAmount = 0
//   let inCollateralValue = 2

//   let test_owner = #"face"

//   let configDatum = tx.configDatumIn()

//   let withdraw0 = tx.withdrawal(t.merkelClose)

//   let loanIn1 = tx.mLoanInput(1, inLoanAmount)
//   let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue)
//   let userIn1 = tx.userInput(2024)

//   let configIn = tx.configInput()

//   let oracleIn = tx.oracleInput(inRatio)
//   let oracleOut = tx.oracleOutput(outRatio)

//   let redeemerList =
//     [(0, 3)]

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       extra_signatories: [test_owner],
//       inputs: [loanIn1, oracleIn, userIn1, colIn1],
//       outputs: [oracleOut],
//       mint: value.to_minted_value(t.loanBurnValue()),
//       withdrawals: withdraw0,
//     }

//   let ctx5 = tx.wCtx(t.merkelClose, tx)

//   close(t.loanMintHash, t.oracleMintHash, redeemerList, ctx5)?
// }

// test loan_token_fail() {
//   let inRatio = 2
//   let outRatio = 2

//   let inLoanAmount = 0
//   let inCollateralAmount = 0
//   let inCollateralValue = 2

//   let test_owner = #"face"

//   let configDatum = tx.configDatumIn()

//   let withdraw0 = tx.withdrawal(t.merkelClose)

//   let loanIn1 = tx.mLoanInput(1, inLoanAmount)
//   let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue)
//   let userIn1 = tx.userInput(2024)

//   let configIn = tx.configInput()

//   let oracleIn = tx.oracleInput(inRatio)
//   let oracleOut = tx.oracleOutput(outRatio)

//   let redeemerList =
//     [(0, 3)]

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       extra_signatories: [test_owner],
//       inputs: [loanIn1, oracleIn, userIn1, colIn1],
//       outputs: [oracleOut],
//       mint: value.to_minted_value(t.loanBurnValue()),
//       withdrawals: withdraw0,
//     }

//   let ctx5 = tx.wCtx(t.merkelClose, tx)

//   close(t.loanMintHash, t.oracleMintHash, redeemerList, ctx5)?
// }

// test oracle_fail() {
//   let inRatio = 2
//   let outRatio = 2

//   let inLoanAmount = 0
//   let inCollateralAmount = 0
//   let inCollateralValue = 2

//   let test_owner = #"face"

//   let configDatum = tx.configDatumIn()

//   let withdraw0 = tx.withdrawal(t.merkelClose)

//   let loanIn1 = tx.mLoanInput(1, inLoanAmount)
//   let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue)
//   let userIn1 = tx.userInput(2024)

//   let configIn = tx.configInput()

//   let oracleIn = tx.oracleInput(inRatio)
//   let oracleOut = tx.oracleOutput(outRatio)

//   let redeemerList =
//     [(0, 3)]

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       extra_signatories: [test_owner],
//       inputs: [loanIn1, oracleIn, userIn1, colIn1],
//       outputs: [oracleOut],
//       mint: value.to_minted_value(t.loanBurnValue()),
//       withdrawals: withdraw0,
//     }

//   let ctx5 = tx.wCtx(t.merkelClose, tx)

//   close(t.loanMintHash, t.oracleMintHash, redeemerList, ctx5)?
// }

// test config_fail() {
//   let inRatio = 2
//   let outRatio = 2

//   let inLoanAmount = 0
//   let inCollateralAmount = 0
//   let inCollateralValue = 2

//   let test_owner = #"face"

//   let configDatum = tx.configDatumIn()

//   let withdraw0 = tx.withdrawal(t.merkelClose)

//   let loanIn1 = tx.mLoanInput(1, inLoanAmount)
//   let colIn1 = tx.mCollateralInput(1, inCollateralAmount, inCollateralValue)
//   let userIn1 = tx.userInput(2024)

//   let configIn = tx.configInput()

//   let oracleIn = tx.oracleInput(inRatio)
//   let oracleOut = tx.oracleOutput(outRatio)

//   let redeemerList =
//     [(0, 3)]

//   let tx =
//     Transaction {
//       ..placeholder(),
//       reference_inputs: [configIn],
//       extra_signatories: [test_owner],
//       inputs: [loanIn1, oracleIn, userIn1, colIn1],
//       outputs: [oracleOut],
//       mint: value.to_minted_value(t.loanBurnValue()),
//       withdrawals: withdraw0,
//     }

//   let ctx5 = tx.wCtx(t.merkelClose, tx)

//   close(t.loanMintHash, t.oracleMintHash, redeemerList, ctx5)?
// }

// // Merkel Loan && Collateral for comparison tests //

// validator(loanVal: ScriptHash, lp: PolicyId, op: PolicyId) {
//   fn loanClose(r: List<Int>, c: ScriptContext) {
//     expect ScriptContext { transaction, purpose: WithdrawFrom(stake_cred) } = c

//     let Transaction { outputs, mint, .. } = transaction

//     expect Inline(ScriptCredential(_own_validator)) = stake_cred

//     expect Some(_oracleOut) =
//       list.find(
//         outputs,
//         fn(output) { list.has(value.policies(output.value), op) },
//       )

//     withBurn(
//       fn(input) {
//         expect InlineDatum(datum) = input.datum
//         expect d: LoanDatum = datum

//         let loanTokenVal = value.without_lovelace(input.value)
//         expect [(loanTn, 1)] =
//           loanTokenVal
//             |> value.tokens(lp)
//             |> dict.to_list()

//         expect Some(burnVal) =
//           value.zero()
//             |> value.add(lp, loanTn, -2)
//             |> value.flatten()
//             |> list.head()

//         let burns =
//           mint
//             |> value.from_minted_value()
//             |> value.flatten()

//         expect list.has(burns, burnVal)
//         d.amount == 0
//       },
//       loanVal,
//       r,
//       transaction,
//     )
//   }
// }

// validator(colVal: ScriptHash, lp: PolicyId, op: PolicyId) {
//   fn collateralClose(r: List<Int>, c: ScriptContext) {
//     expect ScriptContext { transaction, purpose: WithdrawFrom(stake_cred) } = c

//     let Transaction { outputs, mint, .. } = transaction

//     expect Inline(ScriptCredential(_own_validator)) = stake_cred

//     expect Some(_oracleOut) =
//       list.find(
//         outputs,
//         fn(output) { list.has(value.policies(output.value), op) },
//       )

//     withBurn(
//       fn(input) {
//         expect InlineDatum(datum) = input.datum
//         expect d: CollateralDatum = datum

//         let loanTokenVal = value.without_lovelace(input.value)
//         expect [(loanTn, 1)] =
//           loanTokenVal
//             |> value.tokens(lp)
//             |> dict.to_list()

//         expect Some(burnVal) =
//           value.zero()
//             |> value.add(lp, loanTn, -2)
//             |> value.flatten()
//             |> list.head()

//         let burns =
//           mint
//             |> value.from_minted_value()
//             |> value.flatten()

//         expect list.has(burns, burnVal)
//         d.amount == 0
//       },
//       colVal,
//       r,
//       transaction,
//     )
//   }
// }
