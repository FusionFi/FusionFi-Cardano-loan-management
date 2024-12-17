use cardano/address.{Address, Script, VerificationKey}
use cardano/assets
use cardano/transaction.{
  InlineDatum, Input, NoDatum, Output, Transaction, placeholder,
}
use ccfl/types.{CollateralDatum}
use tests/prop
use tests/tools as t
use tests/transactions as tx
use v1/merkel_yieldout

//                      //
// Yield Withdraw Tests //
//                      //

test yieldOutFail((a, b, c, d) via prop.fourInts()) fail {
  let inRatio = 1000
  let outRatio = 1000

  let inCollateralAmount = a * 1000
  let inCollateralValue = b * 1000
  let outYield = c * 1000

  let outCollateralAmount = a * 1000
  let outCollateralValue = d * 1000

  let oref = t.test_oref(#"dede", 1)
  let output =
    Output {
      address: Address {
        payment_credential: Script(#"bebe"),
        stake_credential: None,
      },
      value: assets.from_lovelace(outYield),
      datum: NoDatum,
      reference_script: None,
    }

  let userIn1 = tx.userInput(2024)
  let configIn = tx.configInput()
  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let inDatum =
    CollateralDatum {
      amount: inCollateralAmount,
      timestamp: 1111111111,
      yield: 1000,
    }
  let outDatum =
    CollateralDatum {
      amount: outCollateralAmount,
      timestamp: 1724449574,
      yield: 0,
    }

  let colIn1 =
    t.test_input(
      tx.oref(#"cafe", 1),
      t.test_output(
        t.test_script_address(t.mCol),
        assets.merge(
          assets.from_lovelace(inCollateralValue),
          t.loanTokenValue(),
        ),
        InlineDatum(inDatum),
      ),
    )

  let colOut1 =
    t.test_output(
      t.test_script_address(t.mCol),
      assets.merge(assets.from_lovelace(outCollateralValue), t.loanTokenValue()),
      InlineDatum(outDatum),
    )

  let yieldIn = Input { output_reference: oref, output }

  // withdrawl
  let withdraw0 = tx.withdrawal(t.yieldOut)
  let withdrawRedeemer = tx.withdrawRedeemer([0])

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      inputs: [colIn1, yieldIn, oracleIn, userIn1],
      outputs: [colOut1, oracleOut],
      withdrawals: withdraw0,
    }

  merkel_yieldout.yieldWithdraw.withdraw(
    t.configMintHash,
    withdrawRedeemer,
    VerificationKey(t.yieldIn),
    tx,
  )?
}
