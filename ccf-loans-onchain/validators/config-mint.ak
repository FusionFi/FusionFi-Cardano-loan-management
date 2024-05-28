use aiken/dict
use aiken/list.{find, has}
use aiken/transaction.{
  InlineDatum, Mint, NoDatum, Output, ScriptContext, Transaction, placeholder,
}
use aiken/transaction/value.{policies}
use ccfl/types.{
  ConClose, ConUpdate, ConfigAction, ConfigDatum, VerificationKeyHash,
}
use tests/tools as t
use tests/transactions.{configActionUpdate, configDatum, oracleDatum}

//                       //
// Config Minting Policy //
//                       //

validator(o: VerificationKeyHash) {
  fn configMint(r: ConfigAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Mint(policyId) = purpose

    let Transaction { outputs, extra_signatories, mint, .. } = transaction

    expect [(_tName, tAmt)] =
      mint
        |> value.from_minted_value()
        |> value.tokens(policyId)
        |> dict.to_list()

    when r is {
      ConUpdate { loanVal, colVal, rewardsVal } -> {
        // checks the output with the token
        expect Some(ownOut) =
          find(outputs, fn(output) { has(policies(output.value), policyId) })
        // has the appropriate datum        
        expect InlineDatum(datum) = ownOut.datum
        expect outDatum: ConfigDatum = datum
        // output datum matches redeemer && only 1 token is minted && signed by owner
        outDatum.loanVal == loanVal && outDatum.colVal == colVal && outDatum.rewardsVal == rewardsVal && has(
          extra_signatories,
          o,
        ) && tAmt == 1
      }
      // signed by owner and mint amount is -1
      ConClose -> has(extra_signatories, o) && tAmt == -1
    }
  }
}

//       //
// Tests //
//       //

test config_mint() {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)

  let configAction =
    configActionUpdate(t.loanValHash, t.collateralValHash, t.rewardsMintHash)

  let configDatum1 =
    configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
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
      ..placeholder(),
      mint: t.configMintedValue(),
      extra_signatories: [test_owner],
      inputs: [ownerInput],
      outputs: [configOutput],
    }

  let ctx = ScriptContext { purpose: Mint(t.configMintHash), transaction: tx }

  configMint(test_owner, configAction, ctx)?
}

test config_mint_qty_fail() fail {
  let test_owner = #"face"

  let mintValue =
    value.to_minted_value(
      value.merge(t.configTokenValue(), t.configTokenValue()),
    )

  let oref = t.test_oref(#"face", 1)

  let configAction =
    configActionUpdate(t.loanValHash, t.collateralValHash, t.rewardsMintHash)

  let configDatum1 =
    configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
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
      ..placeholder(),
      mint: mintValue,
      extra_signatories: [test_owner],
      inputs: [ownerInput],
      outputs: [configOutput],
    }

  let ctx = ScriptContext { purpose: Mint(t.configMintHash), transaction: tx }

  configMint(test_owner, configAction, ctx)?
}

test config_mint_datum_fail() fail {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)

  let configAction =
    configActionUpdate(t.loanValHash, t.collateralValHash, t.rewardsMintHash)

  let configDatum1 = oracleDatum(1, 1111111111, 15, 2)
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
      ..placeholder(),
      mint: t.configMintedValue(),
      extra_signatories: [test_owner],
      inputs: [ownerInput],
      outputs: [configOutput],
    }

  let ctx = ScriptContext { purpose: Mint(t.configMintHash), transaction: tx }

  configMint(test_owner, configAction, ctx)?
}

test config_mint_sigs_fail() fail {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)

  let configAction =
    configActionUpdate(t.loanValHash, t.collateralValHash, t.rewardsMintHash)

  let configDatum1 =
    configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
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
      ..placeholder(),
      mint: t.configMintedValue(),
      extra_signatories: [#"cafe"],
      inputs: [ownerInput],
      outputs: [configOutput],
    }

  let ctx = ScriptContext { purpose: Mint(t.configMintHash), transaction: tx }

  configMint(test_owner, configAction, ctx)?
}
