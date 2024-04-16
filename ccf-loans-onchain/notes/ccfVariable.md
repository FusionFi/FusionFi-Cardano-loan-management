# ccfVariable

:up [[ccfContractNotes]]
#smartcontracts

---

## Contracts

[[ccfInit]]

+ `Oracle` has variable fee applied to USD feed `ODatum`
+ `LVal` charges variable fee from previous transaction

---

Variable fee structure will have a field on the oracle which contains the fee structure

this way we can ste it without adding more bloat to the Validator, instead keeping it 
with the datafeed

---

## Examples

Init:
```
ODatum = {
  usdAda: 0.5,
  apr: 15
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

FeeValue = 2 ADA
```

Price Falls:
```
ODatum = {
  usdAda: 0.4, -> value drops
  apr: 15
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
  -> 2 ADA + (apr / 365) loanValue * 2 * exchange
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
  -> 25 ADA + 2 ADA + (apr / 365) loanValue * 8 * exchange
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