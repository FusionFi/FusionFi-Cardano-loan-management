import { Constr, Data, toHex, toUnit, UTxO, fromText } from "https://deno.land/x/lucid@0.10.7/mod.ts";
import { lucid } from "../blockfrost.ts"
import { oracleDatum1, oracleDatum2, oracleDatum3, oracleDatum4, oracleDatum5, oracleDatum6, loanDatum, collateralDatum } from "../datums.ts";
import { ownerAddress, ownerPKH } from "../owner.ts";
import { oracleUpdateAction, mintLoanAction, loanCloseAction, burnLoanAction, loanBalanceAction, loanLiquidateAction, configCloseAction, rewardsMintAction } from "../redeemers.ts";
import { loanCS, configAddr, oracleAddr, loanMint, loanAddr, collateralAddr, oracleVal, closeHash, closeAddr, close, loanVal, collateralVal, balanceAddr, balance, liquidateAddr, liquidate, rewardsCS, rewardsMint } from "../validators.ts";
import { configUnit, oracleUnit, loanAmt, loanUnit, timestamp, oracleTn, rewards, term } from "../variables.ts";

lucid.selectWalletFromPrivateKey(await Deno.readTextFile("./owner.sk"));

export async function mintLoan() {
  console.log(`Loan Minting Transaction
  `)

  const oracleOutDatum = Data.from(oracleDatum1) // Change the oracle datum here
  const deposit = loanAmt * 1000n / oracleOutDatum.fields[0]
  const utxos: UTxO[] = await lucid.utxosAt(ownerAddress)
  const utxo: UTxO = utxos[0]
  const loanTn = utxo.txHash.slice(0, 30).concat(toHex(utxo.outputIndex))
  const loanUnit = toUnit(loanCS, loanTn)
  const configUtxos = await lucid.utxosAtWithUnit(configAddr, configUnit)
  const configIn = configUtxos[0]
  const oracleUtxos: UTxO[] = await lucid.utxosAtWithUnit(oracleAddr, oracleUnit)
  const oracleUtxo: UTxO = oracleUtxos[0]

  console.log(`Loan Unit: `, loanUnit)
  console.log(`Collateral Value: `, deposit * 1000000n)
  console.log(`Expected Collateral: `, ((loanAmt * 1000n) / oracleOutDatum.fields[0]) * 1000000n )
  
  const tx = await lucid
    .newTx()
    .collectFrom([utxo])
    .collectFrom([oracleUtxo], oracleUpdateAction)
    .readFrom([configIn])
    .mintAssets({
      [loanUnit]: 2,
    }, mintLoanAction)
    .attachMintingPolicy(loanMint)
    .payToContract(
      loanAddr, 
      { inline: loanDatum }, 
      { [loanUnit]: 1 }
    )
    .payToContract(
      collateralAddr,
      { inline: collateralDatum },
      { lovelace: (deposit * 1000000n), [loanUnit]: 1 }
    )
    .payToContract(
      oracleAddr,
      { inline: Data.to(oracleOutDatum) },
      { [oracleUnit]: 1 }
    )
    .attachSpendingValidator(oracleVal)
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}

export async function burnLoan() {
  console.log(`BURN LOAN TRANSACTION
    
  Loan Token: `, loanUnit, `
    `)
  const oracleDatum = Data.from(oracleDatum1)
  const lUtxos: UTxO[] = await lucid.utxosAtWithUnit(loanAddr, loanUnit)
  const lUtxo: UTxO = lUtxos[0]
  const cUtxos: UTxO[] = await lucid.utxosAtWithUnit(collateralAddr, loanUnit)
  const cUtxo: UTxO = cUtxos[0]
  const configUtxos = await lucid.utxosAtWithUnit(configAddr, configUnit)
  const configIn = configUtxos[0]
  const oracleUtxos: UTxO[] = await lucid.utxosAtWithUnit(oracleAddr, oracleUnit)
  const oracleUtxo: UTxO = oracleUtxos[0]
  const exchange = oracleDatum[0]
  const inDatum = Data.from(lUtxo.datum)
  const rewardsTn = fromText("")
  const rewardsUnit = toUnit(rewardsCS, rewardsTn)

  const withdrawRedeemer = Data.to(
    new Constr(0, [
      [0n]
    ])
  )

  console.log(lUtxo)
  console.log(cUtxo)
  console.log(oracleUtxo)

  console.log(inDatum)

  const tx = await lucid
    .newTx()
    .collectFrom([lUtxo], loanCloseAction)
    .collectFrom([cUtxo], loanCloseAction)
    .readFrom([configIn])
    .collectFrom([oracleUtxo], oracleUpdateAction)
    .mintAssets({
      [loanUnit]: -2,
    }, burnLoanAction)
    .mintAssets({
      [rewardsUnit]: 5,
    }, rewardsMintAction)
    .attachMintingPolicy(loanMint)
    .attachMintingPolicy(rewardsMint)
    // .payToAddress(
    //   ownerAddress, 
    //   { rewardsUnit: 5 }
    // )
    .payToContract(oracleAddr, 
      { inline: Data.to(oracleDatum) }, 
      { [oracleUnit]: 1 } 
    )
    .withdraw(closeAddr, 0n, withdrawRedeemer)
    .attachSpendingValidator(loanVal)
    .attachSpendingValidator(collateralVal)
    .attachSpendingValidator(oracleVal)
    .attachWithdrawalValidator(close)
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  console.log(`New Oracle Price: `, oracleDatum.fields[0], `
    `)

  return txSigned.submit()

}

// // Loan Validator Transactions //

export async function balanceLoan() {
  console.log(`BALANCE LOAN TRANSACTION
    `)
  // Change Oracle Datum Here
  const oracleDatum = Data.from(oracleDatum1) // set to oracleDatum1 by default
  const oracleExchangeRate = oracleDatum.fields[0]
  const adaValue = loanAmt * 1000n / oracleExchangeRate
  const deposit = adaValue * 1000000n
  const lUtxos: UTxO[] = await lucid.utxosAtWithUnit(loanAddr, loanUnit)
  const lUtxo: UTxO = lUtxos[0]
  const cUtxos: UTxO[] = await lucid.utxosAtWithUnit(collateralAddr, loanUnit)
  const cUtxo: UTxO = cUtxos[0]
  const inDatum = Data.from(lUtxo.datum)
  const configUtxos = await lucid.utxosAtWithUnit(configAddr, configUnit)
  const configIn = configUtxos[0]
  const oracleUtxos: UTxO[] = await lucid.utxosAtWithUnit(oracleAddr, oracleUnit)
  const oracleUtxo: UTxO = oracleUtxos[0]

  const withdrawRedeemer = Data.to(
    new Constr(0, [
      [1n]
    ])
  )

  console.log(inDatum)
  console.log(Data.from(loanDatum))

  console.log(Data.from(cUtxo.datum))
  console.log(Data.from(collateralDatum))

  console.log(lUtxo)
  console.log(cUtxo)

  const tx = await lucid
    .newTx()
    .collectFrom([lUtxo], loanBalanceAction)
    .collectFrom([cUtxo], loanBalanceAction)
    .collectFrom([oracleUtxo], oracleUpdateAction)
    .readFrom([configIn])
    .withdraw(balanceAddr, 0n, withdrawRedeemer)
    .payToContract(
      loanAddr, 
      { inline: loanDatum }, 
      { [loanUnit]: 1 }
    )
    .payToContract(
      collateralAddr,
      { inline: collateralDatum },
      { lovelace: (deposit * 2n),
        [loanUnit]: 1,
      }
    )
    .payToContract(
      oracleAddr,
      { inline: Data.to(oracleDatum) },
      { [oracleUnit]: 1 }
    )
    .attachSpendingValidator(loanVal)
    .attachSpendingValidator(collateralVal)
    .attachSpendingValidator(oracleVal)
    .attachWithdrawalValidator(balance)
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  console.log(`New Oracle Price: `, oracleDatum.fields[0], `
    `)

  return txSigned.submit()
}

export async function liquidateLoan() {
  console.log(`LIQUIDATE LOAN TRANSACTION
    `)
  const oracleDatum = Data.from(oracleDatum6)
  const newLoanValue = 0n
  const lUtxos: UTxO[] = await lucid.utxosAtWithUnit(loanAddr, loanUnit)
  const lUtxo: UTxO = lUtxos[0]
  const inDatum = Data.from(lUtxo.datum)
  const cUtxos: UTxO[] = await lucid.utxosAtWithUnit(collateralAddr, loanUnit)
  const cUtxo: UTxO = cUtxos[0]
  const configUtxos = await lucid.utxosAtWithUnit(configAddr, configUnit)
  const configIn = configUtxos[0]
  const oracleUtxos: UTxO[] = await lucid.utxosAtWithUnit(oracleAddr, oracleUnit)
  const oracleUtxo: UTxO = oracleUtxos[0]
  
  const withdrawRedeemer = Data.to(
    new Constr(0, [
      [1n]
    ])
  )

  const liquidateDatum = Data.to(
    new Constr(0, [
        newLoanValue, 
        newLoanValue, 
        0n, 
        timestamp,
        oracleTn
      ]))

  const liquidCollateralDatum = Data.to(
    new Constr(0, [
      newLoanValue * 2n,
      timestamp
    ])
  )

  console.log(Data.from(lUtxo.datum))

  const tx = await lucid
    .newTx()
    .collectFrom([lUtxo], loanLiquidateAction)
    .collectFrom([cUtxo], loanLiquidateAction)
    .collectFrom([oracleUtxo], oracleUpdateAction)
    .readFrom([configIn])
    .payToContract(
      loanAddr, 
      { inline: liquidateDatum }, 
      { [loanUnit]: 1 }
    )
    .payToContract(
      collateralAddr,
      { inline: liquidCollateralDatum },
      { lovelace: 2000000n, [loanUnit]: 1 }
    )
    .payToContract(
      oracleAddr,
      { inline: Data.to(oracleDatum) },
      { [oracleUnit]: 1}
    )
    .attachSpendingValidator(oracleVal)
    .attachSpendingValidator(loanVal)
    .attachSpendingValidator(collateralVal)
    .withdraw(liquidateAddr, 0n, withdrawRedeemer)
    .attachWithdrawalValidator(liquidate)
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  console.log(`New Oracle Price: `, oracleDatum.fields[0], `
    `)

  return txSigned.submit()
}

export async function repayLoan() {
  const oracleDatum = Data.from(oracleDatum1)
  const exchange = oracleDatum.fields[0]
  const lUtxos: UTxO[] = await lucid.utxosAtWithUnit(loanAddr, loanUnit)
  const lUtxo: UTxO = lUtxos[0]
  const inDatum = Data.from(lUtxo.datum)
  const cUtxos: UTxO[] = await lucid.utxosAtWithUnit(collateralAddr, loanUnit)
  const cUtxo: UTxO = cUtxos[0]
  const configUtxos = await lucid.utxosAtWithUnit(configAddr, configUnit)
  const configIn = configUtxos[0]
  const oracleUtxos: UTxO[] = await lucid.utxosAtWithUnit(oracleAddr, oracleUnit)
  const oracleUtxo: UTxO = oracleUtxos[0]
  const collateralValue = 2000000n
  const remainingValue = 0n
  
  const withdrawRedeemer = Data.to(
    new Constr(0, [
      [1n]
    ])
  )

  const loanDatum = Data.to(
    new Constr(0, [
      remainingValue,  
      rewards, 
      term, 
      timestamp, 
      oracleTn
    ])
  )

  const collateralDatum = Data.to(
    new Constr(0, [
      remainingValue,
      timestamp
    ])
  )

  const tx = await lucid
    .newTx()
    .collectFrom([lUtxo], loanBalanceAction)
    .collectFrom([cUtxo], loanBalanceAction)
    .collectFrom([oracleUtxo], oracleUpdateAction)
    .readFrom([configIn])
    .payToContract(
      loanAddr, 
      { inline: loanDatum }, 
      { [loanUnit]: 1 }
    )
    .payToContract(
      collateralAddr,
      { inline: collateralDatum },
      { lovelace: collateralValue, [loanUnit]: 1 }
    )
    .payToContract(
      oracleAddr,
      { inline: Data.to(oracleDatum) },
      { [oracleUnit]: 1 }
    )
    .withdraw(balanceAddr, 0, withdrawRedeemer)
    .attachSpendingValidator(loanVal)
    .attachSpendingValidator(collateralVal)
    .attachSpendingValidator(oracleVal)
    .attachWithdrawalValidator(balance)
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  console.log(`New Oracle Price: `, oracleDatum.fields[0], `
    `)

  return txSigned.submit()
}