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
cases, similar to  the calssic forward minting pattern but without the creation of 
garbage tokens.

This will allow us to run each redeemer case individually according to a given staking 
validator.

## Merkle reference scripts

We will do mist of our transaction validation with reference scripts. There is a recently
discovered optimisation strategy called merkelised reference scripts. what we do in this
design pattern is have each level of validation in its own refrence script this will let
us ignore all other cases when validating different redeemer cases so we will be able to
make the most out of each case without requiring inputs or outputs from that validator.

This is supposedly a crazy level optimisation which I am looking forward to testing out

I am in touch with the man who discovered this, so I will make a point of leaning on him 
for assistance in implementing this design pattern so I can learn to implement it 
effectively.