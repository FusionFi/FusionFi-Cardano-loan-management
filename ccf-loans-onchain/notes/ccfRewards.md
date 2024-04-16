# ccfRewards

Rewards a token to a use based on the amount of collateral for each timestamp

---

rewards are paid in a native token according to a timestamp in the datum

for this we add a new minting policy and add the rewards timestamp to `LDatum`

we also set a rewards% which is redeemed according to the collateral

Rewards Token Policy
Rewards Distribution Validator?

---

we could force a withdrawal every action on the loan to prevent gamification

in which case we would just need to add the output to the rewards token

or we can update a thread token on a policy which will enable them to withdraw 
at a later date

or we can add it to the loan datum

---

for this example we will create a token minting policy which will mint to claim 
rewards tokens

reward tokens will be updated on the datum at every transaction according to the 
amount of collateral

and they can be minted when closed

if they are liquidated we will ignore them so liquidators dont accumulate based 
on the duration of a loan

---

## Examples 

Init:
```
ODatum = {
  usdAda: 0.5,
  yield: 15,
  timestamp: 0001
}

LDatum = {
  collateral: ADA,
  collateralValue: 1000,
  loanCurrency: USD,
  loanValue: 500, -> liquidates at 588.24,
  rewards: 0
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
  rewards: 0,
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
  rewards: (2 * 1000) * 0.15
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
  rewards: 0
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
  loanValue: 0, 
  rewards: 0,
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
  loanValue: 250, -> leaves 50%
  rewards: 0 -> rewards are not added when in liquidation
  timestamp: 0003
}
```
