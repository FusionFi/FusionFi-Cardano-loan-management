# Loan Interest Calculations

12 motnh loans

200K loan == 17500 monthly repayments

so we can have the total supplied and total borrowed in the oracle token

we can update the loan value every time we add supply

We can automatically change the value when someone takes out a loan

If we add the information to the oracle datum it can be handled at a central point.

We can add the calculations to the withdrawal validators as it will need to be done at each increment

Minting a loan and repaying a loan will both need to handle borrowed values, 

we will need to add a mechanism to adjust the supply at the validator level ( oracle ) for Emurgod/Encryptus to add/remove liquidity to the supply.

we could add a price fee upddate as an extra withdrawal validator to allow us to do this outside of the regular oracle validator,

we will need to add it to the config validator in a different field ( where loan val list us right now )

this should then be a simple addition to the oracle validator without adding too much overhead

t'ie he all yalhdaturs wi whll eiid tu j'ijk ho a given fee is added to an output

I will also need to do another calculation for fiat loans to account for the 0.4% transaction fee

---

