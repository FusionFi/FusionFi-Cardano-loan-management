# ccfFeesRates

Applying fees and rates to the contracts to earn against the loan

---

:up [[CCFContractNotes]]
#smartcontracts

---

To apply fees easily we will add them as parameters to the contract

These fees are fixed for this reason but it will allow us a way to create rewards 
for users, regardless

---

## Contracts 

Same as before [[ccfInit]]

assuming a given fee structure set in the Loan Vault, every time an action is taken against the loan, a fee and interest is charged.

We need to use the timestamps in this so annual rates can be applied incrementally

A fixed processing fee can be applied to each transaction as well which can also be 
made variable [[ccfVariable]]

// To demonstrate this we will just modify the `Init` Loan Vault and assume the rest //

Loan Validator:
  - parameterises tx fee & fixed rate
  - fee is paid on any transaction
  - apr is applied based on previous timestamp

---

Update ->
  charges 2ADA per transaction
  takes daily rate 15% APR

Liquidate -> 
  charges 2ADA per transaction
  liquidation gets at 15%

Close -> 
  charges nothing for owner sig
  charges 2ADA for Tx
  charges interest to date

---

## Examples

Init:
```
ODatum = {
  usdAda: 0.5,
  timestamp: 0001
}

LDatom = {
  collateral: ADA,
  collateralValue: 1000,
  loanCurrency: USD,
  loanValue: 500, -> liquidates at 588.24
  timestamp: 0001
}

LValue = 2000 ADA 
  (loan value / exchange) / 0.5

FeeValue = 2 ADA
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

FeeOut = 
  -> 2 ADA + (15 / 365) loanValue * 2 * exchange
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
  -> 25 ADA + 2 ADA + (15 / 365) loanValue * 8 * exchange
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

FeeOut = 525.5 ADA

Liquidator = 4.5 ADA
```

we always withdraw our collateral at 1.0 

15% goes to the liquidator (we can add a manual cap to this or adjust it 
as a reward mechanism)

this can incentivise people to take part and operate liquidator bots to make the 
system operate decentralisedly