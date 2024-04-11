use aiken/transaction.value
use aiken/transaction
use aiken/credential

type MintAction {
  Mint
  Burn
}

type OracleAction {
  Update 
  Close
}

type OracleDatum {
  usdAda: Int,
  timestamp: PosixTime,
}

type LoanAction {
  Balance
  Liquidate
  Close
}

type LoanDatum {
  collateral: ByteArray, // asset As String e.g. "ADA"
  collateralValue: Int, 
  loanCurrency: ByteArray, // e.g. "USD"
  loanValue: Int,
  timeStamp: PosixTime,
}

// Loan Mint //

validator {
  fn mintLoan(r: MintAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Mint(policyId) = purpose

    let [(tName, tAmt)] =
      mint
        |> value.fromMintedValue()
        |> value.tokens(policyId)
        |> dict.toList()

    when r.a is {
      Mint -> True
      Burn -> True
    }
  }
}

// Loan Vault //

validator {
  fn loanVault(d: LoanDatum, r: LoanAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect SPend(oref) = purpose

    let Transaction { inputs, outputs, reference_inputs, .. } = transasction

    when r.a is {
      Balance -> True
      Liquidate -> True
      Close -> True
    }
  }
}

// Price Oracle //

validator(o: Owner) {
  fn priceOracle(d: OracleDatum, r: OracleAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Spend(oref) = purpose

    when r.a is {
      Update -> True
      Close -> True
    }
  }
}

// Oracle Mint //

validator(o: Owner) {
  fn oracleMint(r: OracleAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Mint(policyId) = purpose

    when r.a is {
      Mint -> True
      Burn -> True
    }
  }
}
