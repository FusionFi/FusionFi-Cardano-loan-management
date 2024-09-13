use cardano/address.{Address, Script}
use cardano/assets
use cardano/transaction.{InlineDatum, NoDatum, Output, Transaction, placeholder}
use ccfl/types.{CollateralDatum}
use ori/merkel_yieldin
use tests/prop
use tests/tools as t
use tests/transactions as tx

//                     //
// Yield Deposit Tests //
//                     //

test yieldInFail((a, b, c, d) via prop.fourInts()) fail {
  let inRatio = 1000
  let outRatio = 1000

  let inCollateralAmount = a * 1000
  let inCollateralValue = b * 1000

  let outCollateralAmount = a * 1000
  let outCollateralValue = c * 1000
  let outYield = d * 1000

  let userIn1 = tx.userInput(2024)
  let configIn = tx.configInput()
  let oracleIn = tx.oracleInput(inRatio)
  let oracleOut = tx.oracleOutput(outRatio)

  let inDatum =
    CollateralDatum {
      amount: inCollateralAmount,
      timestamp: 1111111111,
      yield: 0,
    }
  let outDatum =
    CollateralDatum {
      amount: outCollateralAmount,
      timestamp: 1724449574,
      yield: outYield,
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

  let yieldOut =
    Output {
      address: Address {
        payment_credential: Script(t.yieldVault),
        stake_credential: None,
      },
      value: assets.from_lovelace(outYield),
      datum: NoDatum,
      reference_script: None,
    }

  // withdrawl
  let withdraw0 = tx.withdrawal(t.yieldIn)
  let withdrawRedeemer = tx.withdrawRedeemer([0])

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      inputs: [colIn1, oracleIn, userIn1],
      outputs: [colOut1, yieldOut, oracleOut],
      withdrawals: withdraw0,
    }

  merkel_yieldin.yieldDeposit.withdraw(
    t.configMintHash,
    withdrawRedeemer,
    Script(t.yieldIn),
    tx,
  )?
}
