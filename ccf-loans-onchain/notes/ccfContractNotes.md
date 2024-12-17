# CCFContractNotes

## Initial notes from spec

### Smart Contracts

Vault - store collateral with loan data
LoanToken - mints token with loan data
?LiquidatorToken - Token to enable liqudation

### Revenue 
depositFee
withdrawalFee

---

## Smart Contracts

We could use an oracle for onchain data
anyone can update it according to an api which checks the current value against fiat
allowing anyone to update it will allow liquidators to collect if something is available,
and we can charge a small fee for doing this.

Otherwise there will be a daily update we pay as our fee?

This will verify LTV values to enable liquidation or trigger a margin call

We may need a way to make borrowers private?

You can add to your collateral at any time

margin calls happen if:
- ratio is above 50% for 3 days
- ratio hits 65% incur fee
- ratio hits 75% incur another fee

liquidation can happen if:
- ratio hits 85%

MintLoan - Users mint a token with loanData when they take out a loan
  Datum:
    { Collateral
    , CollateralValue
    , LoanCurrency
    , LoanValue
    , Intrest
    }

Update

### Oracle

We need to be able to deploy an oracle and close one.

this will allow us to release new price feeds for different fiat currencies in future

We want to be able to update the oracle feed on a regular schedule automatically

We might want to allow liquidators to update the feed to enable liquidation checks onchain

we could actually force this.

### Loan Minting Policy

To create a loan we need to have an updated fee

We need to mint a token to represent each loan.

We need to burn the token when a loan is closed.

### Loan Vault

This validator will hold all of the loan tokens

It will enforce spending rules

you can add collateral to the loan

pay interest

perform margin call updates

liquidate

close

---

## Transactions

Mint an oracle token with price data
- oracle minting policy
- oracle validator

update price data
- oracle validator

create a loan
- loan minting policy
- loan validator
- oracle validator refIn

balance a loan
- loan validator
- oracle validator refIn

liquidate a loan
- loan validator
- oracle validator refIn
- loan minting policy?

close a loan
- loan validator
- loan minting policy

---

## Trustability

How can we maintain an honest oracle?

- update it ourselves regularly ( expensive )
- force liquidators to update it ( problematic for scheduling & workflow)
- enforce any change to the loan contracts to update the oracle ( consistent )

If we update the oracle feed with every transaction that happens that would mean
we also need to consume that utxo `can you reference historic utxos?`

we want to reduce bloat in transactions as much as possible so we may need to try and 
reduce the size of the validators to seperate logic

---

## Separation Of Logic

We could use a kind of CIP68 token to create sets of loan tokens

One could hold the data in one validator
The other could lock the collateral

We can use an asset comparison to allow changes / make calculations

We could also do this with different assets for different types of actions

so each function would have its own token with a datum and would provide context 
for the main validator

---

## Meld Style

Users deposit tokens as collateral and are able to borrow up to 50% of the value 
  of that asset
Their deposits should accrue yield
Withdraw at any time

you can pay off your loan at your convenience provided they maintain their position 
appropriately
interest is added in time based intervals

If the collateral to debt ratio hits a certain threshold it will be marked for liquidation
when it is marked a `liquidator` can trade those assets out of the loan ( its 85% )

---

## Mock Ups

this is an short explanation of the different contract versions i have written with 
links to a deeper explanation.

### Init
[[ccfInit]]

The init version is a basic framework for the processes which we will use as a template
for future versions and variations of onchain validation.

Oracle Minting Policy
Oracle Validator 
Loan Minting Policy
Loan Vault

### Collateral and Data Separation - TODO
[[ccfColSeparation]]

We will use a token pair to separate the collateral and the loan state data

Oracle
Loan Pair Minting Policy
Loan State Validator
Loan Collateral Validator

### Fees & Rates
[[ccfFeesRates]]

Applying Rates and Fees to contracts

### Variable Rates
[[ccfVariable]]

Applying variable fees through an oracle

### Rewards
[[ccfRewards]]

Can we pay a token reward for a use of the contracts? or for holding a position for 
a certain amount of time?

