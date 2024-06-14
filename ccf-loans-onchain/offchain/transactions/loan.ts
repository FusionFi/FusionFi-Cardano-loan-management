import { Constr, Data, toHex, toUnit, UTxO, } from "https://deno.land/x/lucid@0.10.7/mod.ts";
import { lucid } from "../blockfrost.ts"
import { oracleDatum1, loanDatum, collateralDatum } from "../datums.ts";
import { ownerAddress, ownerPKH } from "../owner.ts";
import { oracleUpdateAction, mintLoanAction, loanCloseAction, burnLoanAction, loanBalanceAction, loanLiquidateAction } from "../redeemers.ts";
import { loanCS, configAddr, oracleAddr, loanMint, loanAddr, collateralAddr, oracleVal, closeHash, closeAddr, loanVal, collateralVal, balanceAddr, balance, liquidateAddr, liquidate } from "../validators.ts";
import { configUnit, oracleUnit, loanAmt, loanUnit, timestamp, oracleTn, rewards, term } from "../variables.ts";

lucid.selectWalletFromPrivateKey(await Deno.readTextFile("./owner.sk"));

export async function mintLoan() {
  console.log(`Loan Minting Transaction
  `)

  const utxos: UTxO[] = await lucid.utxosAt(ownerAddress)
  const utxo: UTxO = utxos[0]
  const loanTn = utxo.txHash.slice(0, 30).concat(toHex(utxo.outputIndex))
  const loanUnit = toUnit(loanCS, loanTn)
  const configUtxos = await lucid.utxosAtWithUnit(configAddr, configUnit)
  const configIn = configUtxos[0]
  const oracleUtxos: UTxO[] = await lucid.utxosAtWithUnit(oracleAddr, oracleUnit)
  const oracleUtxo: UTxO = oracleUtxos[0]
  const oracleOutDatum = Data.from(oracleDatum1) // Change the oracle datum here
  const deposit = loanAmt * 1000n / oracleOutDatum.fields[0]

  console.log(`Loan Token Name: `, loanTn)
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
    `)
  const lUtxos: UTxO[] = await lucid.utxosAtWithUnit(loanAddr, loanUnit)
  const lUtxo: UTxO = lUtxos[0]
  console.log(`Loan Utxo: `, lUtxo, `
    `)
  const cUtxos: UTxO[] = await lucid.utxosAtWithUnit(collateralAddr, loanUnit)
  const cUtxo: UTxO = cUtxos[0]
  console.log(`Collateral Utxo: `, cUtxo, `
    `)
  const configUtxos = await lucid.utxosAtWithUnit(configAddr, configUnit)
  const configIn = configUtxos[0]
  const oracleUtxos: UTxO[] = await lucid.utxosAtWithUnit(oracleAddr, oracleUnit)
  const oracleUtxo: UTxO = oracleUtxos[0]
  const oracleDatum = Data.from(oracleUtxo.datum)
  const exchange = oracleDatum[0]
  const inDatum = Data.from(lUtxo.datum)

  const withdrawRedeemer = Data.to(
    new Constr(0, [
      [1n]
    ])
  )

  console.log(`ConfigDatum: `, Data.from(configIn.datum), `
    `)
  
  console.log(`Close Hash: `, closeHash, `
    `)

  const tx = await lucid
    .newTx()
    .collectFrom([lUtxo], loanCloseAction)
    .collectFrom([cUtxo], loanCloseAction)
    .readFrom([configIn])
    .collectFrom([oracleUtxo], oracleUpdateAction)
    .mintAssets({
      [loanUnit]: -2,
    }, burnLoanAction)
    .attachMintingPolicy(loanMint)
    .payToContract(oracleAddr, 
      { inline: oracleDatum1 }, 
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

  return txSigned.submit()

}

// // Loan Validator Transactions //

export async function balanceLoan() {
  console.log(`BALANCE LOAN TRANSACTION
    `)
  const lUtxos: UTxO[] = await lucid.utxosAtWithUnit(loanAddr, loanUnit)
  const lUtxo: UTxO = lUtxos[0]
  console.log(lUtxo)
  const cUtxos: UTxO[] = await lucid.utxosAtWithUnit(collateralAddr, loanUnit)
  const cUtxo: UTxO = cUtxos[0]
  console.log(cUtxo)
  const inDatum = Data.from(lUtxo.datum)
  const configUtxos = await lucid.utxosAtWithUnit(configAddr, configUnit)
  const configIn = configUtxos[0]
  console.log(configIn)
  const oracleUtxos: UTxO[] = await lucid.utxosAtWithUnit(oracleAddr, oracleUnit)
  const oracleUtxo: UTxO = oracleUtxos[0]
  console.log(oracleUtxo)
  const oracleDatum = Data.from(oracleDatum1)
  const oracleExchangeRate = oracleDatum.fields[0]
  const adaValue = loanAmt * 1000n / oracleExchangeRate
  const deposit = adaValue * 1000000n
  // console.log(redeemerList)
  const withdrawRedeemer = Data.to(
    new Constr(0, [
      [0n]
    ])
  )

  console.log(`WithdrawRedeemer Redeemer: `, Data.from(withdrawRedeemer))

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
      { lovelace: deposit,
        [loanUnit]: 1,
      }
    )
    .payToContract(
      oracleAddr,
      { inline: oracleDatum1 },
      { [oracleUnit]: 1 }
    )
    .attachSpendingValidator(loanVal)
    .attachSpendingValidator(collateralVal)
    .attachSpendingValidator(oracleVal)
    .attachWithdrawalValidator(balance)
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}

export async function liquidateLoan() {
  console.log(`LIQUIDATE LOAN TRANSACTION
    `)
  const newLoanValue = 0n
  const lUtxos: UTxO[] = await lucid.utxosAtWithUnit(loanAddr, loanUnit)
  const lUtxo: UTxO = lUtxos[0]
  console.log(lUtxo)
  const inDatum = Data.from(lUtxo.datum)
  const cUtxos: UTxO[] = await lucid.utxosAtWithUnit(collateralAddr, loanUnit)
  const cUtxo: UTxO = cUtxos[0]
  console.log(cUtxo)
  const configUtxos = await lucid.utxosAtWithUnit(configAddr, configUnit)
  const configIn = configUtxos[0]
  console.log(configIn)
  const oracleUtxos: UTxO[] = await lucid.utxosAtWithUnit(oracleAddr, oracleUnit)
  const oracleUtxo: UTxO = oracleUtxos[0]
  console.log(oracleUtxo)
  const withdrawRedeemer = Data.to(
    new Constr(0, [
      [0n]
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
      { inline: oracleDatum1 },
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

  return txSigned.submit()
}

export async function repayLoan() {
  const lUtxos: UTxO[] = await lucid.utxosAtWithUnit(loanAddr, loanUnit)
  console.log(loanAddr)
  const lUtxo: UTxO = lUtxos[0]
  const inDatum = Data.from(lUtxo.datum)
  const cUtxos: UTxO[] = await lucid.utxosAtWithUnit(collateralAddr, loanUnit)
  const cUtxo: UTxO = cUtxos[0]
  const configUtxos = await lucid.utxosAtWithUnit(configAddr, configUnit)
  const configIn = configUtxos[0]
  const oracleUtxos: UTxO[] = await lucid.utxosAtWithUnit(oracleAddr, oracleUnit)
  const oracleUtxo: UTxO = oracleUtxos[0]
  const oracleDatum = Data.from(oracleUtxo.datum)
  const exchange = oracleDatum.fields[0]
  const collateralValue = 2000000n
  const remainingValue = 0n
  
  const withdrawRedeemer = Data.to(
    new Constr(0, [
      [0n]
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

  console.log(`Loan In UTxO: `, lUtxo, `
    `)
  console.log(`Collateral In UTxO: `, cUtxo, `
    `)
  console.log(`Loan Redeemer: `, withdrawRedeemer)

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
      { inline: oracleDatum1 },
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

  return txSigned.submit()
}