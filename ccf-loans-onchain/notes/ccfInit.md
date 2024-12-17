# CCFInit

CCF Init Contracts - The starting point for further development

---

:up [[CCFContractNotes]]
#smartcontracts

---

The initial version of this contract is the most minimal form of functionality for 
basic transactions to be run.

It has fixed collateral policies for minValues and liquidation

## Contracts

Oracle Minting Policy `OMint`
Oracle Validator `OVal`
Loan Minting Policy `lMint`
Loan Vault Validator `LVal`

(We will also need a reference script to point to the Loan Validator
  - this could be done in the oracle for now?
)

OracleMintingPolicy:
- mints to `OVal`
- mints with `ODatum`
- burns

OracleValidator:
- holds `OMint` Token
- Has `ODatum`
- updates `ODatum` to new exchange rate

LoanMintingPolicy:
- mints to `LVal` 
- mints `LMint` token
- mints with `LDatum` 
- mints with minimum 50% `LTV` 

LoanValidator:
- holds `LMint` token
- holds `Collateral`
- has `LDatum`
- updates `Collateral` to new exchange rate
- liquidates partial value at 85% `LTV`
- closes when `LoanValue` is 0

This will allow us to:

Take out a loan and deposit enough `Collateral` to satisfy 50% `LTV` according to
the `Oracle`

We can update the `Collateral` to satisfy the 50% `LTV` at any point

If the `Oracle` price is at 85% `LTV` someone can `Liquidate` a partial value of the
`LoanValue` at the ratio to `Collateral`

This will bring down the `LoanValue` and `Collateral` evenly

## What Is Missing?

A way to charge fees

---

## Examples

Init:
```
ODatum = {
  usdAda: 0.5,
  timestamp: 0001
}

LDatum = {
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
  collateralValue: 800, -> must be increased accordingly
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
```

Partial Liquidation:
```
LValue = 1000 ADA
  -> 50% of the loan is liquidated

LDatum = {
  collateral: ADA,
  collateralValue: 265, -> leaves 50%
  loanCurrency: USD,
  loanValue: 250 -> leaves 50%
  timestamp: 0003
}
```
