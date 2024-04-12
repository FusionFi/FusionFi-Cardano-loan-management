use aiken/transaction.value
use aiken/transaction
use aiken/credential

type MintAction {
  Mint { loanCurrency: ByteArray, loanValue: Int, timestamp: PosixTime }
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
  a = Balance | Liquidate | Close
  b = PosixTime
  c = Int
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
  fn loanMint(r: MintAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Mint(policyId) = purpose

    let Transaction { mint, outputs, reference_inputs, .. } = transaction

    let [(tName, tAmt)] =
      mint
        |> value.fromMintedValue()
        |> value.tokens(policyId)
        |> dict.toList()

    when r.a is {
      Mint -> {
        let refIn = filter(reference_inputs, fn(ref) {
          has(policies(ref.output.value, o), 1)
          let InlineDatum(datum) = ref.output.datum
          expect rDatum: OracleDatum = datum
        })
        
        let exchangeRate = rDatum.usdAda

        any(outputs, fn(output) {
          has(policies(output.value, policyId), 1)
          let InlineDatum(datum) = output.datum
          
          expect datum: LoanDatum {
            collateral: "ADA",
            collateralValue: (r.loanValue * exchangeRate) / 0.5
            loanCurrency: "USD",
            loanValue: r.loanValue
            timeStamp: r.timestamp,
          }
        
          lovelace_of(output.value) >= datum.collateralValue * 1000000
        })
      }

      Burn -> True
    }
  }
}

// Loan Vault //

validator(p: PolicyId, o: PolicyId) {
  fn loanVault(d: LoanDatum, r: LoanAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect SPend(oref) = purpose

    let Transaction { inputs, outputs, reference_inputs, .. } = transasction

    expect Some(ref) = find(reference_inputs, fn(input) {
        has(policies(input.output.value, o))
      }
    )

    let exchange = ref.output.datum.usdAda

    when r.a is {
      Balance -> {

        let ownOut = ok.get_own_singleton_output(c)
        let adaOut = lovelace_of(ownOut.value) / 1000000
        let newCollateralValue = adaOut * exchange
        let minCollateralValue = (ownOut.datum.loanValue / exchange) / 0.5
        
        expect has(policies(ownOut.value), p)
        expect InlineDatum(datum) = ownOut.datum
        expect datum: LoanDatum = datum
        expect newDatum: LoanDatum = {
          collateral: d.collateral
          collateralValue: newCollateralValue, 
          loanCurrency: d.loanCurrency,
          loanValue: d.loanValue,
          timeStamp: r.b,
        }

        adaOut >= minCollateralValue

      }
      Liquidate -> {
        
        let ownOut = ok.get_own_singleton_output(c)
        let adaOut = lovelace_of(ownOut.value) / 1000000
        let newCollateralValue = adaOut * exchange
        let minCollateralValue = (ownOut.datum.loanValue / exchange) / 0.85
        
        expect has(policies(ownOut.value), p)
        expect InlineDatum(datum) = ownOut.datum
        expect datum: LoanDatum = datum
        expect newDatum: LoanDatum = {
          collateral: d.collateral
          collateralValue: newCollateralValue, 
          loanCurrency: d.loanCurrency,
          loanValue: d.loanValue - r.c,
          timeStamp: r.b,
        }

        adaOut >= minCollateralValue

      }
      Close -> oref.datum.loanValue <= 0
    }
  }
}

// Price Oracle //

validator(o: Owner, p: PolicyId) {
  fn oracleVault(d: OracleDatum, r: OracleAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Spend(oref) = purpose

    when r.a is {
      Update -> {
        let out = ok.get_own_singleton_output(o)
        expect [(_, 1)] = 
          |> without_lovelace(out.value)
          |> tokens(p)
          |> to_list()
        
        expect InlineDatum(datum) = out.datum
        expect datum: OracleDatum = datum

        ok.tx_signed_by(c.transaction, o)
      }
      Close -> 
        expect Transaction { mint, .. } = transaction
        
        expect Some(input) = find_input(inputs, ownRef)

        expect [(oName, 1)] = // get singleton name
          |> without_lovelace(input.output.value)
          |> tokens(p)
          |> to_list()
        
        expect [(oName, -1)] =
          mint
            |> value.fromMintedValue()
            |> value.tokens(p)
            |> dict.toList()

        ok.tx_signed_by(c.transaction, o)
    }
  }
}

// Oracle Mint //

validator(o: Owner) {
  fn oracleMint(r: OracleAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Mint(policyId) = purpose

    when r is {
      Mint -> True
      Burn -> True
    }
  }
}
