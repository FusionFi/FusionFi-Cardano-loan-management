# ccf-loans

---

Currently working on V3 Testing - Supply Pools for Crypto && P2P Lending

See full description of V3 validator architecture here:

[ValidatorArchitecture](./validatorArchitecture.md)

## Running Validator Tests

To run the validator tests, simply run `aiken check` in the repo.

We are currently working on a full set of unit and property tests for all of the V3 validators.

There are basic passing test cases for each of the new validators, but there is more
work to be completed befor we have all potential cases and vulnerabilities covered.

The V1 validators currently being used in the frontend are all complete.

## Running Your Own Test Transactions

> NOTE - When you mint an oracle or a loan, you will need to record the tokens (Units) in 
> `offchain/variables.ts` to be used for later transactions.

Once you have built the validators, you can run the command at the top of `config.ts` to
execute these transactions on the preview testnet.

You need to first mint a `config` token, then an `oracle`, then you can mint `loans`.

In `config.ts` comment out all of the transactions except `mintConfigTx`

```
// mintConfig
const mintConfigTx = await mintConfig()
console.log(`Mint Config Tx: 
  `, mintConfigTx, `

NEXT RUN THE ORACLE MINTING TRANSACTION
`)
```

Then you can run the script in the terminal:

```
deno run --allow-net --allow-read --allow-env config.ts
```

The terminal will povide some transaction data so you can review what is going on.

Before you mint any loans or oracles, start by registering the script addresses for the 
withdrawal validators.

If you dont do this, none of your loan transactions will work because you cannot 
`WithdrawFrom` the script.

Change the validator script in `offchain/transactions/helpers.ts`:

```
export async function registerStake() {
  const tx = await lucid
    .newTx()
    .registerStake(closeAddr) // balanceAddr | liquidateAddr | closeAddr
    .complete()
  
  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}
```

And run the `helpers.ts` script:

```
deno run --allow-net --allow-read --allow-env helpers.ts
```

You are then able to do withdrawal transactions with those scripts, so you can go ahead and mint an `oracle` and `loan`

As shown above, some of the transactions come with instructions. This is important or the
other transactions will fail because they dont have the oracle token.

You will need to save the `Oracle Unit` at `const oracleUnit` in `offchain/variables.ts`

The same goes with your `Loan Unit`, you will be prompted in this way so you dont forget.

---

For scope of contracts and documentation please refer to `notes` 

---

## Structure

```bash
.
├── aiken.lock
├── aiken.toml
├── lib
│   ├── ccfl
│   │   ├── helpers.ak # validator helper functions
│   │   ├── helpersv3.ak # helper utils for V3 validators
│   │   ├── interestcalcs.ak # interest calculations
│   │   ├── types.ak # datums & redeemers
│   │   └── types3.ak # datums & redeemers for V3 validators
│   └── tests
│       ├── helpers.ak # testing helpers
│       ├── optimisation # optimisation tests for helper functions
│       ├── prop.ak # property test utils
│       ├── tools.ak # Test types and values
│       └── transactions.ak # Test Transaction helpers
├── notes # conceptual notes on validators
├── plutus.json # validator blueprint
├── README.md # You Are Here
└── validators
    ├── testnet # dummy Stablecoin validator for testing
    ├── tests # validator tests for V1, V2, V3
    │     └── ...
    ├── V1 # Currently in use in dapp
    ├── V2 # First layer of optimisation
    └── V3 # Implementation Of Supply Pools for P2P && Crypto lending
        ├── balance.ak # Balance Collateral to Loan value
        ├── close.ak # Close an Oracle and Supply Pool
        ├── collateral.ak # Collateral Vault
        ├── config.ak # initial validators w/ tests
        ├── interest.ak # locks oracle token with interest datum
        ├── lend.ak # validates new loan
        ├── liquidate.ak # validates loan liquidation
        ├── loan.ak # loan minting & loan datum lock
        ├── oracle.ak # mints oracleTuple and locks oracle datum
        ├── pool.ak # mints pool LP and locks supply
        ├── repay.ak # repay loan + interest
        ├── supply.ak # supply assets & mint lp
        └── withdraw.ak # remove supply & burn lp
```

## Building

```sh
aiken build
```

I have saved the script hashes in `lib/tests/tools.ak` so we can run the tests without
needing to build, so that we can have test functions to generate dynamic data.

## Testing

```sh
aiken check
```

I have refactored the tests to make them more readable and easier to adapt.

*This only applies to `merkel-liqudate`, `merkel-liquidate` & `merkel-close`*

Now all of the test variables are easy to find and adjust to make it easy to test
different values, without haveng to search through 100+ lines of code to find the
appropriate value.

```rust
test merkel_balance_single() {
  let inRatio = 2
  let outRatio = 2

  let inLoanAmount = 1000
  let inCollateralAmount = 1000
  let inCollateralValue = 2000

  let outLoanAmount = 1000
  let outCollateralAmount = 1000
  let outCollateralValue = 2000

  ...
}
```

Changing these values will adjust the test data in different ways:

### Oracle Data (exchange rate)

This is the in/out exchange rate for the oracle, so the below example makes ADA $2

```rust
  let inRatio = 2
  let outRatio = 2
```

If you want to tests validators for different exchange rates you can change the `outRatio` as that is what is always used by the validators.

### Loan Amount (loanDatum.amount)

This is the recorded loan amount at the `loanDatum`

```rust
  let inLoanAmount = 1000

  ...

  let outLoanAmount = 1000
```

If you want to adjust this for your own testing, the validation logic always checks the
`outLoanAmount` against the `outRatio` above & `outCollateralValue` below.

### Collateral Value (loan collateral)

The amount of ADA or other tokens in the collateral UTxO

```rust
  let inCollateralValue = 2000

  ...

  let outCollateralValue = 2000
```

All of these validation tests are done on a single user input to make the tests smaller 
and easier to read/edit.

The larger (3 i/o) tests are done for throughput and benchmarking to understand the 
impact of different optimisations.

>NOTE: Currently theses tests only make it easy to adjust basic values, I have 
>implemented token checks but I havent made it easier to make token adjustments or output 
>address adjustments. This will be done at end of week.

We currently have 2 types of tests running with `aiken check`

1 - Validator proof tests -> verify logic to ensure expected behaviour
2 - Optimisation comparison tests -> see the improvements of the optimisations

Validator Tests:
- `balance` `liquidate` & `close` tests for expected behaviour
- failing tests for each element of Tx validation to prove things fail if incorrect

These are pretty standard tests with slight discrepencies in validation to check fail
cases e.g. Collateral output doesnt match Loan value & Oracle exchange rate

The current Optimisation Tests compare:
- combined redeemer cases for `merkel` validators
- `merkel-balance` combines `Balance` logic
- `merkel-close` combines `Close` logic
- `merkel-liquidate` combines `Liquidate` logic

The merkel design pattern is about reducing script bloat to increase throughput. We can 
have several loans being manipulated each tx, without having to attach the whole script 
every time.

To compare the two validators, we have matching transactions:

Multi Transaction

- 3 `LoanInputs` && `CollateralInputs` interacting per Test
- 1 Test for each `LoanAction` && `CollateralAction`

Single Transaction

- 1 `LoanInputs` && `CollateralInputs` interacting per Test
- 1 Test for each `LoanAction` && `CollateralAction`

Here were my latest test results:

![image](./CCFLMerkelBalanceTests.png)

This only shows one validator but the full scope of updated tests.

## Periferal Validators

I have single user tests for the utility validators like `oracle-val` because throughput 
isn't an issue here.

The tests verify several levels of validation, i have 2 fails here and comments in the 
test explaining why

---

## Validator Architecture - V3

This is a description of the latest version of the validators (V3)

This iteration was aimed at adding a P2P supply pool for assets to allow the community
to lend out their own assets.

For more information on these validators refer to (ValidatorArchitecture)[./validatorArchitecture.md]

### Supply Pool

There are several different functions that we need to enable users to make for this
feature set: 

- Supply assets to a pool
- Withdraw assets from a pool
- Borrow assets from a pool
- Close a pool 

Pools have a matching oracle token so we can track the interest rates and price feeds for
the pool. This also helps us match the real pools to the oracles as well.

### Oracle

Oracles are now comprised of 3 matching tokens: 

- Oracle Price
- Interest Rates
- Supply Pool

If the price feed is for Fiat there will be an empty supply pool, but it will still have
an oracle token in it as we will use it for validation.

The `oracle` validator mints/burns and locks the oracle price feed, this is what will be
used in most transactions as it will have the main datum. The other tokens are special
use tokens used for specific functions.

When an oracle is deployed, it mints 3 tokens and attaches the relevant data to each 
datum, locked in the relevant validator.

### Config

The Dapp state token validator.

There will only be one config token used as the state manager for the validators.

This token/validator will manage the updating or addition of features to the dapp.

It will be used as a reference input for all of the transactions to supply the script
hashes to the validators dynamically.

### Loan / Collateral 

These validators ar responsible for storing the loan data and the collateral

A loan token pair is minted when a user takes a loan out, this is done using `loan`. 
The `loan` validator holds the loan Datum and the collateral is sent to `collateral`.

### Withdrawal Validators

All of the other validators are used to manage the various actions users may want to take
during the lifetime of their loan/supply.

- Balance -> balances `LTV` ratio according to the oracle
- Close -> Closes an Oracle ( can only be donbe by team )
- Lend -> Take a loan from supply pool
- Liquidate -> Liquidate a loan that has passed `LTV` threshold
- Repay -> Repay a loan ++ interest ( closes loan if 0 )
- Supply -> Supply assets to a pool
- Withdraw -> withdraws supplied assets

Each of these validators checks multiple IO's from the various vaults ( above validators )
and checks the full state of the transaction according to the various datums & values
at each UTxO.

---

## Validator Architecture - V1

Here is a brief description of the validators and their roles.

### Oracle - Onchain price feed (`mint` / `spend`)

Oracle Minting Policy:
  - onChain price token
  - mints, burns
  - sets initial tokenDatum

Oracle Validator:
  - onChain price feed
  - updates & closes feed
  - enforces tokenDatum

The Oracle is a token / validator pair which identify the correct data onchain.

This is checked in every loan transaction to guarantee we are always using the most up-to-date price for validation (by checking the oracle output)

### Config - ValidatorState reference_input (`mint` / `spend`)

Config Minting Policy:
  - onChain script feed
  - mints, burns
  - sets initial configDatum

Config Validator:
  - onChain script lookup
  - updates & closes feed
  - enforces configDatum

The Config is a token / validator pair which identifies the dapp state onchain by 
providing all of the script hashes of the other validators.

*Why not use parameters?*

Using parameters locks the validator to those parameters - if the parameters change, you 
are using a different vaildator.

Making them dynamic in this way adds bloat to the transactions, but it means we can 
update the other validators and it wont affect the rest of the dapp ( or even the users/
loans ).

### Rewards - Rewards Tokens (`mint`)

Rewards Minting Policy:
  - Mints Rewards Tokens

The Rewards Token is earned by maintaining a loan position, you accrue rewards periodicaly 
and can mint them when you close out your loan - meaning it has been returned.

If you are liquidated you will lose your rewards.

### Loans - Holds loanData (`mint` / `spend`)

Loan Minting Policy:
  - onChain Loan identifiers
  - mints, burns tokenPair
  - enforces datums & initial values

Loan Validator:
  - onChain loan state
  - updates, liquidates & closes loan
  - enforces loanDatum & collateralValue

Collateral Validator:
  - onChain collateral
  - updates, liquidates & closes loan
  - enforces collateralDatum & collateralValue

The Loans validators are the main logic of the dapp.

We have a minting policy which mints a loan token pair, one is sent to Loan Vault with 
the loan datum, the other goes to the collateral vault with the collateral.

We separate these values so they can be updated individually whilst maintaining the 
onchain connection with their loan token.

## Withdrawal Validator Design Pattern

This design pattern separates the redeemer cases out of the `init` into separate 
`staking` validators

It makes use of `withdraw 0` but in checks a different `stake credential` for each 
redeemer case

```rust

type LoanAction {
  SLBalance
  SLLiquidate
  SLClose
}

// && 

type CollateralAction {
  SCBalance
  SCLiquidate
  SCClose
}

```

Becomes the `MerkelConfigDatum.CollateralRedeemers` in the reference input

```rust

pub type MerkelConfigDatum {
  loanVal: ScriptHash,
  colVal: ScriptHash,
  rewardsVal: ScriptHash,
  oracleVal: ScriptHash,
  loanRedeemers: List<ScriptHash>, 
  collateralRedeemers: List<ScriptHash>, // Attached Here For Testing
}

```

The script hashes are referenced by each spend redeemer, so it checks for that 
`StakeCredential`

```rust

// r.i is the redeemer that has an index of the List<ScriptHash>
...
expect Some(stakeVal) =
  cDatum.loanRedeemers
    |> list.at(r.i)
// checks in tx.withdrawals
dict.has_key(withdrawals, Inline(ScriptCredential(stakeVal)))
...

```

The withdrawal sripts themselves execute the validation logic against a list of loan &
collateral outputs

```rust

fn balance(r: List<(Int, Int)>, c: ScriptContext) {
  // This executes the same logic as: 
  // loan-vault Redeemer SLBalance && collateral-vault Redeemer SCBalance combined
  // it checks all of the inputs and outputs based on the list
}

```

## Further Optimisation

I have some work to do on the periferal utility validators like `oracle` and `rewards`

There are some validation checks i need to address - as highlighted in the tests

I also need to refactor the tests in those validators

