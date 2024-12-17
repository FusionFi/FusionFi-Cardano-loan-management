# CCF Collateral & Data Separation

CCF Collateral and Data Separation Contract - mockup

---

:up [[CCFContractNotes]]
#smartcontracts

---

For Collateral and Data Separation we will have a second loanToken minted

One will hold the loan information, the other will identify the collateral

---

## Contracts

Oracle Minting Policy `OMint`
Oracle Validator `OVal`
Loan Minting Policy `lMint`
Loan Vault Validator `LVal`
Collateral Vault Validator `CVal`

// To demonstrate this concept The demo will only hold the Loan & Collateral 
Validators with an assumed PolicyId and Oracle //

LoanMintingPolicy:
  - mints loan token pair
  - sends to `LVal` with `LDatum`
  - sends to `CVal` with `Collateral`
  - mints with >= 50% `LTV`
  - burns token pairs

LoanValidator:
  - holds `LDatum` at token utxo
  - updates `LDatum` with `Collateral` change
  - requires both tokens to update `LDatum`

CollateralValidator:
  - holds `Collateral` at token utxo
  - 

---

We can then sign transactions every time collateral is updated, and enforce fees based 
on that. 

We can also use timestamps to identify when the last payment happened - or the next 
deadline - and automatically incur fees if it is not adhered to.

---

## Examples

These contracts work the same way init does however we can set the timestamp to margin call on loans

Init:
```
ODatum = {
  usdAda: 0.5,
  timestamp: 0001
}

LData = {
  collateral: ADA,
  collateralValue: 1000,
  loanCurrency: USD,
  loanValue: 500, -> liquidates at 588.24
  timestamp: 0001
}

LValue = 2000 ADA 
  (loan value / exchange) / 0.5
```

Price Falls:
```
ODatum = {
  usdAda: 0.4, -> value drops
  timestamp: 0002
}

LDatum = {
  collateral: ADA,
  collateralValue: 800, -> timestamped new collateral value
  loanCurrency: USD,
  loanValue: 500,
  timestamp: 0002
}
```

Update Collateral:
```
LValue = 2500 ADA 
  -> increased to balance collateral

LDatum = {
  collateral: ADA,
  collateralValue: 1000,
  loanCurrency: USD,
  loanValue: 500,
  timestamp: 0003
}
```

Update Late:
```
LValue = 2500 ADA 
  -> increased to balance collateral

LDatum = {
  collateral: ADA,
  collateralValue: 1000,
  loanCurrency: USD,
  loanValue: 500,
  timestamp: 0008
}

FeeOut = 25 ADA
  -> sent to owner Param
```

Price Liquidation:
```
ODatum = {
  usdAda: 0.265, -> price drops
  timestamp: 0002
}

LDatum = {
  collateral: ADA,
  collateralValue: 530, -> collateral can be liquidated
  loanCurrency: USD,
  loanValue: 500,
  timestamp: 0002
}

LValue = 2000 ADA
```

Liquidate Collateral:
```
LValue = 0 ADA
  -> liquidates full value (min UTxO remains)

LDatum = {
  collateral: ADA,
  collateralValue: 0,
  loanCurrency: USD,
  loanValue: 0
  timestamp: 0003
}

FeeOut = 530 ADA
  -> Burns Both Tokens
```