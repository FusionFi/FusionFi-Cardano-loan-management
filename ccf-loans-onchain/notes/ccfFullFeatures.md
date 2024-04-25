# CCF Full Features

CCF Full Feature set implementation - mockup

---

:up [[CCFContractNotes]]
:contracts [[fullFeatureSet.ak]]
#smartcontracts 

---

This document describes the full feature set validator file

I have implemented all of the other validators in this mockup so we can begin to optimise 
the validator structure with the full scope according to my notes.

---

## Contracts

VariableOracle - Oracle price feed with a variable APR and fee structure
OracleMint - Minting policy for Oracle price feed
ConfigValidator - Reference input containing script hashes of key validators
ConfigMint - Minting policy for config token
RewardsMint - Minting policy for rewards tokens
LoanMint - Loan token pair minting policy
LoanVault - Locking validator for loan data
CollateralVault - Locking validator for loan collateral

Variable Oracle:
  - contains Oracle token for the given asset
  - enables datum updates to oracle token
    - token pair rate
    - apr
    - fees

Oracle Mint:
  - mints Oracle token
  - sends to Variable Oracle
  - intialises data feed for asset pair and rates

Config Validator:
  - contains Config token
  - stores script hashes of key validators
  - enables validator upgrades

Config Mint:
  - mints Config token
  - initialises validator configuration

Rewards Mint:
  - mints Rewards tokens when a loan is closed

Loan Mint:
  - mints Loan token pair
  - initialises Loan onchain
  - sends to Loan Vault & Collateral Vault
  - burns Loan token pair to close a loan

Loan Vault: 
  - stores Loan data with token
  - contains key data for loan:
    - loan value
    - min collateral
    - last payment timestamp
    - accrued rewards

Collateral Vault:
  - stores the collateral with token
  - contains key collateral information

---

## Contract Details & Design

This collection of contracts enables a few small features by default, such as future 
'upgradability' of validators, which otherwise would be difficult or nearly impossible
to achieve.

Using a Configuration token/vault with script hashes helps us avoid a circular dependancy
and allows us to achieve this upgradability by updating the config information and 
applying it as a reference script to key transactions.

Separating the collateral from the loan data will enable us to use the collateral for 
yield generating purposes, which we will be able to define in the future, without risking 
the loss of data integrity - this combined with the amount value stored at the collateral 
datum.

Having the fee structure in the oracle datum allows us to apply those fees at the point
of transactions or interaction with the loan/collateral.

It also enables us to adjust the fee structure as and when necessary, and will let us
apply different fee structures to different assets (if/when we start accepting other 
assets as collateral).

Recording a timestamp of transactions at the datum will enable us to apply our fees and 
rates automatically at each transaction enabling us to earn those fees regularly without 
a separate process for doing so, and without it affecting the collateral/loan ratios.

These validators force an update to the oracle feed every transaction, so we can have 
regular and automated oracle updates embedded in all other processes, helping to maintain 
an up to date and accurate price feed, without having to manually do it ourselves at the 
cost of every transaction.

Our rewards process with the reward minting policy will help incentivise people to 
maintain a loan position, locking up collateral with us. Only providing these rewards 
at the point someone closes their position will mean that these rewards are only realised 
if a loan is closed and not if it is liquidated.

---

## Transaction Descriptions

Initialising the application:

to start up the dapp we will need to apply parameters to the scripts and mint the config 
token to the config validator with the script hashes at the datum.



---

## Notes & Considerations

None of these processes are set in stone as of right now, however i believe we are in a 
good place now to make decisions on which features can/should be enabled based on review 
from the team.

With this in mind we can easily make adjustments to the validators but we have a good 
scope to start evaluating the direction we want to take, and how we could approach 
challenges we may face with the service we are aiming to provide.

These contracts are not optimised for performance and are obviously not ready to launch,
but we can start to plan our optimisations so we are ready to apply general best practices
for validators when the scope is fully defined.

---

