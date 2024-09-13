use cardano/assets
use cardano/transaction.{InlineDatum, NoDatum, Transaction, placeholder}
use ori/config_mint
use tests/tools as t
use tests/transactions.{mConUpdate, mConfigDatum, oracleDatumIn}

//                      //
// Config Minting Tests //
//                      //

test config_mint() {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)

  let configAction =
    mConUpdate(
      t.loanValHash,
      t.collateralValHash,
      t.rewardsMintHash,
      t.oracleValHash,
      t.interestValHash,
      t.collateralRedeemers(),
    )

  let configDatum1 =
    mConfigDatum(
      t.loanValHash,
      t.collateralValHash,
      t.rewardsMintHash,
      t.oracleValHash,
      t.interestValHash,
      #"bebe",
      t.collateralRedeemers(),
    )

  let outDatum = InlineDatum(configDatum1)

  let ownerInput =
    t.test_input(
      oref,
      t.test_output(t.test_address(test_owner), t.makeAdaValue(10), NoDatum),
    )

  let configOutput =
    t.test_output(
      t.test_script_address(t.configValHash),
      t.configValue(),
      outDatum,
    )

  let tx =
    Transaction {
      ..placeholder,
      mint: t.configMintedValue(),
      extra_signatories: [test_owner],
      inputs: [ownerInput],
      outputs: [configOutput],
    }

  config_mint.configMint.mint(test_owner, configAction, t.configMintHash, tx)?
}
