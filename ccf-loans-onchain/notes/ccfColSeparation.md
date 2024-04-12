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

// To demonstrate this concept The deom will only hold the Loan & Collateral Validators with an assumed PolicyId and Oracle //

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

