use aiken/fuzz as f
use cardano/assets
use cardano/transaction.{InlineDatum, NoDatum, Transaction, placeholder}
use ori/loan_mint
use tests/prop
use tests/tools as t
use tests/transactions.{
  collateralDatum, configDatumIn, loanDatum, loanMintActionMint, oracleDatum,
}

//                 //
// Loan Mint Tests //
//                 //

test loan_mintFail((l, c) via prop.colFuzz()) fail {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)
  let cref = t.test_oref(#"cafe", 2)
  let rref = t.test_oref(#"dead", 6)

  let mintAction = loanMintActionMint(l, 12, 1111111114)

  let loanMintedValue = assets.merge(t.loanTokenValue(), t.loanTokenValue())

  let configInDatum = configDatumIn()

  let loanDatum = loanDatum(l, 0, 12, 1111111114, #"beef")
  let loanOutDatum = InlineDatum(loanDatum)
  let loanOutValue = t.loanTokenValue()

  let collateralDatum = collateralDatum(c, 12, 0)
  let colOutDatum = InlineDatum(collateralDatum)
  let colOutValue = assets.merge(t.makeAdaValue(c + 2), t.loanTokenValue())

  let oracleInDatum = oracleDatum(2000, 11111112, 1000000, 200000, "USD")
  let oracleOutDatum = oracleDatum(1000, 11111114, 1000000, 200000, "USD")
  let oInDatum = InlineDatum(oracleInDatum)
  let oOutDatum = InlineDatum(oracleOutDatum)

  let noDatum = NoDatum

  let userIn =
    t.test_input(
      oref,
      t.test_output(t.test_address(#"cafe"), t.makeAdaValue(2010), noDatum),
    )

  let configIn =
    t.test_input(
      cref,
      t.test_output(
        t.test_script_address(t.configValHash),
        t.configValue(),
        configInDatum,
      ),
    )

  let oracleIn =
    t.test_input(
      rref,
      t.test_output(
        t.test_script_address(t.oracleValHash),
        t.oracleValue(),
        oInDatum,
      ),
    )

  let oracleOut =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      t.oracleValue(),
      oOutDatum,
    )

  let loanOut =
    t.test_output(
      t.test_script_address(t.merkelLoanSpend),
      loanOutValue,
      loanOutDatum,
    )

  let colOut =
    t.test_output(
      t.test_script_address(t.merkelCollateralSpend),
      colOutValue,
      colOutDatum,
    )

  let tx =
    Transaction {
      ..placeholder,
      reference_inputs: [configIn],
      mint: loanMintedValue,
      extra_signatories: [test_owner],
      inputs: [userIn, oracleIn],
      outputs: [loanOut, colOut, oracleOut],
    }

  // let txPass =
  loan_mint.loanMint.mint(
    t.oracleMintHash,
    t.configMintHash,
    mintAction,
    t.loanMintHash,
    tx,
  )
  // f.label(
  //   if txPass == True {
  //     trace @"loanAmount": l
  //     trace @"collateralAmount": c
  //     @"True"
  //   } else {
  //     @"False"
  //   },
  // )
}
