use cardano/assets
use cardano/transaction.{InlineDatum, NoDatum, Transaction, placeholder}
use ccfl/types.{OMint}
use ori/oracle_mint
use tests/tools as t
use tests/transactions.{configInput, interestDatum, oracleDatum}

//                   //
// Oracle Mint Tests //
//                   //

test oracle_mint() {
  let test_owner = #"face"

  let exchange = 500
  let timestamp = 11111111
  let currency = "USD"
  let supply = 1000000
  let borrowed = 200000
  let base = 55
  let optimal = 70
  let slope1 = 40
  let slope2 = 300
  let term = 12

  let oracleMintAction =
    OMint {
      exchange,
      timestamp,
      currency,
      supply,
      borrowed,
      base,
      optimal,
      slope1,
      slope2,
      term,
    }

  let oref = t.test_oref(#"face", 1)

  let oracleDatum1 =
    oracleDatum(exchange, timestamp, supply, borrowed, currency)
  let interestDatum = interestDatum(base, optimal, slope1, slope2, term)
  let outDatum = InlineDatum(oracleDatum1)
  let configIn = configInput()

  let ownerInput =
    t.test_input(
      oref,
      t.test_output(t.test_address(test_owner), t.makeAdaValue(10), NoDatum),
    )

  let oracleOutput =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      t.oracleValue(),
      outDatum,
    )

  let interestOutput =
    t.test_output(
      t.test_script_address(t.interestValHash),
      t.oracleValue(),
      InlineDatum(interestDatum),
    )

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      mint: t.oracleMintedValue(),
      extra_signatories: [test_owner],
      inputs: [ownerInput],
      outputs: [oracleOutput, interestOutput],
    }

  oracle_mint.oracleMint.mint(
    test_owner,
    t.configMintHash,
    oracleMintAction,
    t.oracleMintHash,
    tx,
  )?
}

test mint_qtyFail() fail {
  let test_owner = #"face"

  let mintedValue = assets.from_asset(t.oracleMintHash, #"beef", 3)

  let exchange = 500
  let timestamp = 11111111
  let currency = "USD"
  let supply = 1000000
  let borrowed = 200000
  let base = 55
  let optimal = 70
  let slope1 = 40
  let slope2 = 300
  let term = 12

  let oracleMintAction =
    OMint {
      exchange,
      timestamp,
      currency,
      supply,
      borrowed,
      base,
      optimal,
      slope1,
      slope2,
      term,
    }

  let oref = t.test_oref(#"face", 1)

  let oracleDatum1 =
    oracleDatum(exchange, timestamp, supply, borrowed, currency)
  let interestDatum = interestDatum(base, optimal, slope1, slope2, term)
  let outDatum = InlineDatum(oracleDatum1)
  let configIn = configInput()

  let ownerInput =
    t.test_input(
      oref,
      t.test_output(t.test_address(test_owner), t.makeAdaValue(10), NoDatum),
    )

  let oracleOutput =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      t.oracleValue(),
      outDatum,
    )

  let interestOutput =
    t.test_output(
      t.test_script_address(t.interestValHash),
      t.oracleValue(),
      InlineDatum(interestDatum),
    )

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      mint: mintedValue,
      extra_signatories: [test_owner],
      inputs: [ownerInput],
      outputs: [oracleOutput, interestOutput],
    }

  oracle_mint.oracleMint.mint(
    test_owner,
    t.configMintHash,
    oracleMintAction,
    t.oracleMintHash,
    tx,
  )?
}

test mint_datumFail() fail {
  let test_owner = #"face"

  let exchange = 500
  let timestamp = 11111111
  let currency = "USD"
  let currency2 = "EUR"
  let supply = 1000000
  let borrowed = 200000
  let base = 55
  let optimal = 70
  let slope1 = 40
  let slope2 = 300
  let term = 12

  let oracleMintAction =
    OMint {
      exchange,
      timestamp,
      currency,
      supply,
      borrowed,
      base,
      optimal,
      slope1,
      slope2,
      term,
    }

  let oref = t.test_oref(#"face", 1)

  let oracleDatum1 =
    oracleDatum(exchange, timestamp, supply, borrowed, currency2)
  let interestDatum = interestDatum(base, optimal, slope1, slope2, term)
  let outDatum = InlineDatum(oracleDatum1)
  let configIn = configInput()

  let ownerInput =
    t.test_input(
      oref,
      t.test_output(t.test_address(test_owner), t.makeAdaValue(10), NoDatum),
    )

  let oracleOutput =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      t.oracleValue(),
      outDatum,
    )

  let interestOutput =
    t.test_output(
      t.test_script_address(t.interestValHash),
      t.oracleValue(),
      InlineDatum(interestDatum),
    )

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      mint: t.oracleMintedValue(),
      extra_signatories: [test_owner],
      inputs: [ownerInput],
      outputs: [oracleOutput, interestOutput],
    }

  oracle_mint.oracleMint.mint(
    test_owner,
    t.configMintHash,
    oracleMintAction,
    t.oracleMintHash,
    tx,
  )?
}

test mint_tokenFail() fail {
  let mintedValue = assets.from_asset(t.oracleMintHash, #"beef", 3)

  let test_owner = #"face"

  let exchange = 500
  let timestamp = 11111111
  let currency = "USD"
  let supply = 1000000
  let borrowed = 200000
  let base = 55
  let optimal = 70
  let slope1 = 40
  let slope2 = 300
  let term = 12

  let oracleMintAction =
    OMint {
      exchange,
      timestamp,
      currency,
      supply,
      borrowed,
      base,
      optimal,
      slope1,
      slope2,
      term,
    }

  let oref = t.test_oref(#"face", 1)

  let oracleDatum1 =
    oracleDatum(exchange, timestamp, supply, borrowed, currency)
  let interestDatum = interestDatum(base, optimal, slope1, slope2, term)
  let outDatum = InlineDatum(oracleDatum1)
  let configIn = configInput()

  let ownerInput =
    t.test_input(
      oref,
      t.test_output(t.test_address(test_owner), t.makeAdaValue(10), NoDatum),
    )

  let oracleOutput =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      t.oracleValue(),
      outDatum,
    )

  let interestOutput =
    t.test_output(
      t.test_script_address(t.interestValHash),
      t.oracleValue(),
      InlineDatum(interestDatum),
    )

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      mint: mintedValue,
      extra_signatories: [test_owner],
      inputs: [ownerInput],
      outputs: [oracleOutput, interestOutput],
    }

  oracle_mint.oracleMint.mint(
    test_owner,
    t.configMintHash,
    oracleMintAction,
    t.oracleMintHash,
    tx,
  )?
}

test mint_tokenMultiFail() fail {
  let oracleToken = assets.from_asset(t.oracleMintHash, #"cafe", 1)
  let mintedValue =
    assets.from_asset(t.oracleMintHash, #"cafe", 2)
      |> assets.merge(t.oracleTokenValue())

  let test_owner = #"face"

  let exchange = 500
  let timestamp = 11111111
  let currency = "USD"
  let supply = 1000000
  let borrowed = 200000
  let base = 55
  let optimal = 70
  let slope1 = 40
  let slope2 = 300
  let term = 12

  let oracleMintAction =
    OMint {
      exchange,
      timestamp,
      currency,
      supply,
      borrowed,
      base,
      optimal,
      slope1,
      slope2,
      term,
    }

  let oref = t.test_oref(#"face", 1)

  let oracleDatum1 =
    oracleDatum(exchange, timestamp, supply, borrowed, currency)
  let interestDatum = interestDatum(base, optimal, slope1, slope2, term)
  let outDatum = InlineDatum(oracleDatum1)
  let configIn = configInput()

  let ownerInput =
    t.test_input(
      oref,
      t.test_output(t.test_address(test_owner), t.makeAdaValue(10), NoDatum),
    )

  let oracleOutput =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      t.oracleValue(),
      outDatum,
    )

  let interestOutput =
    t.test_output(
      t.test_script_address(t.interestValHash),
      t.oracleValue(),
      InlineDatum(interestDatum),
    )

  let oracleOutput1 =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      assets.merge(assets.from_lovelace(2000000), oracleToken),
      outDatum,
    )

  let interestOutput1 =
    t.test_output(
      t.test_script_address(t.interestValHash),
      assets.merge(assets.from_lovelace(2000000), oracleToken),
      InlineDatum(interestDatum),
    )

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      mint: mintedValue,
      extra_signatories: [test_owner],
      inputs: [ownerInput],
      outputs: [oracleOutput, interestOutput, oracleOutput1, interestOutput1],
    }

  oracle_mint.oracleMint.mint(
    test_owner,
    t.configMintHash,
    oracleMintAction,
    t.oracleMintHash,
    tx,
  )?
}
