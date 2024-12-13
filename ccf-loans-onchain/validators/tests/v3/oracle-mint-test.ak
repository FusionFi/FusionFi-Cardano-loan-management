use cardano/assets
use cardano/transaction.{InlineDatum, NoDatum, Transaction, placeholder}
use ccfl/typesv3.{MerkelConfigDatum, OMint, SupplyDatum}
use tests/tools as t
use tests/transactions.{configInput, interestDatum, oracleDatum} as tk
use v3/oracle_mint

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

  let oracleMintValue = assets.from_asset(t.oracleMintHash, #"beef", 3)

  let oracleDatum1 =
    oracleDatum(exchange, timestamp, supply, borrowed, currency)
  let interestDatum = interestDatum(base, optimal, slope1, slope2, term)
  let outDatum = InlineDatum(oracleDatum1)
  let supplyDatum = SupplyDatum { policy: "USD", asset: "" }
  let configDatum =
    MerkelConfigDatum {
      loanVal: #"5555",
      colVal: #"4444",
      oracleVal: t.oracleValHash,
      interestVal: t.interestValHash,
      supplyVal: #"ffff",
      collateralRedeemers: [],
      supplyRedeemers: [],
    }

  let configIn =
    t.test_input(
      tk.oref(#"2222", 2),
      t.test_output(
        t.test_script_address(#"3333"),
        assets.from_asset(#"2222", "", 1),
        InlineDatum(configDatum),
      ),
    )

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

  let supplyOutput =
    t.test_output(
      t.test_script_address(#"ffff"),
      t.oracleValue(),
      InlineDatum(supplyDatum),
    )

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      mint: oracleMintValue,
      extra_signatories: [test_owner],
      inputs: [ownerInput],
      outputs: [oracleOutput, interestOutput, supplyOutput],
    }

  oracle_mint.oracleMint.mint(
    test_owner,
    #"2222",
    oracleMintAction,
    t.oracleMintHash,
    tx,
  )?
}
