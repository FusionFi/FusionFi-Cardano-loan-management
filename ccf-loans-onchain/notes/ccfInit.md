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
