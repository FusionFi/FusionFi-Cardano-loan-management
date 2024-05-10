# Optimisation Considerations

Looking at the full feature example, it is clear we can potentially be running a lot 
of different levels of validation at all parts of the contract collection.

In order to make the most of each blockspace and to allow the most throughput to each 
of the contracts we will need to employ a few opotimisation strategies along with the
general design patterns I have used to implement each of the different features.

Here are some ideas I will be exploring under the assumption that ALL of the example 
features will be included in the CCF features.

## splitting logic

stripping validation logic and separating it out across all of the necessary validators
this will be done to prevent duplicate checks occuring at any level of transaction
validation.

## withdraw 0

Verrifying checks through staking contracts will allow us to check individual redeemer 
cases, similar to  the classic forward minting pattern but without the creation of 
garbage tokens.

This will allow us to run each redeemer case individually according to a given staking 
validator.

## Merkle reference scripts

We will do most of our transaction validation with reference scripts. There is a recently
discovered optimisation strategy called merkelised reference scripts. what we do in this
design pattern is have each level of validation in its own refrence script this will let
us ignore all other cases when validating different redeemer cases so we will be able to
make the most out of each case without requiring inputs or outputs from that validator.

This is supposedly a crazy level optimisation which I am looking forward to testing out

I am in touch with the man who discovered this, so I will make a point of leaning on him 
for assistance in implementing this design pattern so I can learn to implement it 
effectively.

---

Essentially at this point the validators arent running that much logic individually, I 
will need to fill up the tests with more realistic dummy data which will allow me to 
have a better picture of the effects we can have on mem & cpu.

My current strategy for operation is to see what checks need to be done on every 
transaction level, what can be relied on by a single check, and what can be done with 
the full scope of transactions.

That is for optimising at the validator level, next is to look at the transaction level.

How can we minimise script calls to allow the greatest throughput?

we can use a withdraw0 at any bottleneck and we can do something like one to many or one 
to one transactions to help manage those expected outputs.

I can also try and figure out th merklised validators so i can get that implemented.

I think it is just a withdraw script for every redeemer case and then that redeemer case 
is the logic applied for the withdrawal.

with that we can focus on running withdrawals for scripts we need to execute only, if i 
am understanding it right.

---

## Optimisations

We have a few options for optimisation but assuming we go with the Merkle V if it suits the use case I have proposed above, we will need to make some adjustments to how the validators work and the data structures used.

we will need to add a list of all the validators to the config datum so we can reference them on the fly, then we can use an index value in the redeemer so we can apply the spending logic appropriately.

if this works as i envision it, it will mean that we only call the appropriate redeemer case per transaction which will allow us to save a lot of space in transactions and let us have a much higher throughput.

I will start with regular stake validator logic and incrementally expand into the merkle val as necessary when i know it is working at each level.

