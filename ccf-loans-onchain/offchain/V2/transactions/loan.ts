import { Constr, Data, toHex, toUnit, UTxO, fromText } from "https://deno.land/x/lucid@0.10.7/mod.ts";
import { lucid } from "../blockfrost.ts"
import { oracleDatum1, oracleDatum2, oracleDatum3, oracleDatum4, oracleDatum5, oracleDatum6, loanDatum, collateralDatum, oracleDatum7, yieldDatum } from "../datums.ts";
import { ownerAddress, ownerPKH, interestPayAddr } from "../owner.ts";
import { oracleUpdateAction, mintLoanAction, loanCloseAction, burnLoanAction, loanBalanceAction, loanLiquidateAction, configCloseAction, rewardsMintAction, loanRepayAction, depositYieldAction, withdrawYieldAction } from "../redeemers.ts";
import { loanCS, configAddr, oracleAddr, loanMint, loanAddr, collateralAddr, oracleVal, closeHash, closeAddr, close, loanVal, collateralVal, balanceAddr, balance, liquidateAddr, liquidate, rewardsCS, rewardsMint, repayAddr, repay, interestAddr, yieldAddr, deposit, depositAddr, withdrawAddr, withdraw, yieldVal } from "../validators.ts";
import { configUnit, oracleUnit, loanAmt, loanUnit, timestamp, oracleTn, rewards, term, interestCalc } from "../variables.ts";

lucid.selectWalletFromPrivateKey(await Deno.readTextFile("./owner.sk"));

export async function mintLoan() {
  // console.log(`Loan Minting Transaction
  // `)

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

  console.log(`Loan Unit: 
    ${loanUnit}
    `)
  console.log(`Collateral Value: `, deposit * 1000000n * 2n, `
    `)
  console.log(`Expected Collateral: `, ((loanAmt * 1000n) / oracleOutDatum.fields[0]) * 1000000n * 2n, `
  ` )

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
      { lovelace: (deposit * 1000000n * 2n), [loanUnit]: 1 }
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

export async function closeLoan() {
  // console.log(`BURN LOAN TRANSACTION

  // Loan Token: `, loanUnit, `
  //   `)
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
  const rewardsQty = inDatum.fields[1]
  const rewardsTn = fromText("")
  const rewardsUnit = toUnit(rewardsCS, rewardsTn)

  const withdrawRedeemer = Data.to(
    new Constr(0, [
      [0n]
    ])
  )

  // console.log(lUtxo)
  // console.log(cUtxo)

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
      [rewardsUnit]: rewardsQty,
    }, rewardsMintAction)
    .attachMintingPolicy(loanMint)
    .attachMintingPolicy(rewardsMint)
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

  // console.log(`New Oracle Price: `, oracleDatum.fields[0], `
  //   `)

  return txSigned.submit()

}

export async function burnLoan() {
  // console.log(`BURN LOAN TRANSACTION

  // Loan Token: `, loanUnit, `
  //   `)
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

  const withdrawRedeemer = Data.to(
    new Constr(0, [
      [0n]
    ])
  )

  // console.log(lUtxo)
  // console.log(cUtxo)

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

  // console.log(`New Oracle Price: `, oracleDatum.fields[0], `
  //   `)

  return txSigned.submit()

}

// // Loan Validator Transactions //

export async function balanceLoan() {
  // console.log(`BALANCE LOAN TRANSACTION
  //   `)
  // Change Oracle Datum Here
  const oracleDatum = Data.from(oracleDatum1) // set to oracleDatum1 by default
  const oracleExchangeRate = oracleDatum.fields[0]
  const adaValue = loanAmt * 1000n / oracleExchangeRate
  const deposit = adaValue * 1000000n
  const lUtxos: UTxO[] = await lucid.utxosAtWithUnit(loanAddr, loanUnit)
  const lUtxo: UTxO = lUtxos[0]
  const cUtxos: UTxO[] = await lucid.utxosAtWithUnit(collateralAddr, loanUnit)
  const cUtxo: UTxO = cUtxos[0]
  const inDatum = Data.from(cUtxo.datum)
  const configUtxos = await lucid.utxosAtWithUnit(configAddr, configUnit)
  const configIn = configUtxos[0]
  const oracleUtxos: UTxO[] = await lucid.utxosAtWithUnit(oracleAddr, oracleUnit)
  const oracleUtxo: UTxO = oracleUtxos[0]
  const minValue = (deposit * 2n) - inDatum.fields[2]

  const withdrawRedeemer = Data.to(
    new Constr(0, [
      [1n]
    ])
  )

  // console.log(inDatum)
  // console.log(Data.from(loanDatum))

  // console.log(Data.from(cUtxo.datum))
  // console.log(Data.from(collateralDatum))

  // console.log(lUtxo)
  // console.log(cUtxo)

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
      {
        lovelace: minValue,
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

  // console.log(`New Oracle Price: `, oracleDatum.fields[0], `
  //   `)

  return txSigned.submit()
}

export async function liquidateLoan() {
  // console.log(`LIQUIDATE LOAN TRANSACTION
  //   `)
  const oracleDatum = Data.from(oracleDatum7)
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
      timestamp,
      0n
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
      { [oracleUnit]: 1 }
    )
    .attachSpendingValidator(oracleVal)
    .attachSpendingValidator(loanVal)
    .attachSpendingValidator(collateralVal)
    .withdraw(liquidateAddr, 0n, withdrawRedeemer)
    .attachWithdrawalValidator(liquidate)
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  // console.log(`New Oracle Price: `, oracleDatum.fields[0], `
  //   `)

  return txSigned.submit()
}

export async function repayLoan() {
  const oracleDatum = Data.from(oracleDatum1)
  const interestUtxos = await lucid.utxosAtWithUnit(interestAddr, oracleUnit)
  const interestIn = interestUtxos[0]
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

  const loanValue = inDatum.fields[0]
  const interestTimeframe = Number(timestamp - inDatum.fields[3]) * interestCalc(5.5, 70, 4, 300, 1000000, 200000) /// 100 + 1)
  const accruedInterest = BigInt(Math.floor((Number(loanValue * 1000n / exchange) * interestTimeframe) / 1000000))

  const timeframe = 31556926000 / (Number(timestamp - inDatum.fields[3]))
  const interest = interestCalc(5.5, 70, 4, 300, 1000000, 200000)
  const recalc = (Number(loanValue) * interest) / timeframe
  const interestP = recalc * 1000 / Number(exchange)
  const payment = Math.floor(interestP * 1000000) + 1

  console.log(timestamp)
  console.log(timeframe)
  console.log(interest)
  console.log(recalc)
  console.log(interestP)
  console.log(payment)

  const withdrawRedeemer = Data.to(
    new Constr(0, [
      [1n]
    ])
  )

  // console.log(lUtxo)

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
      timestamp,
      0n
    ])
  )

  const tx = await lucid
    .newTx()
    .collectFrom([lUtxo], loanRepayAction)
    .collectFrom([cUtxo], loanRepayAction)
    .collectFrom([oracleUtxo], oracleUpdateAction)
    .readFrom([configIn])
    .readFrom([interestIn])
    .withdraw(repayAddr, 0, withdrawRedeemer)
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
    .payToAddress(
      interestPayAddr,
      { lovelace: (BigInt(payment) + 2000000n) },
    )
    .attachSpendingValidator(loanVal)
    .attachSpendingValidator(collateralVal)
    .attachSpendingValidator(oracleVal)
    .attachWithdrawalValidator(repay)
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  // console.log(`New Oracle Price: `, oracleDatum.fields[0], `
  //   `)

  return txSigned.submit()
}

export async function depositYield() {
  const yieldAmt = 1000000n
  const cUtxos: UTxO[] = await lucid.utxosAtWithUnit(collateralAddr, loanUnit)
  const cUtxo: UTxO = cUtxos[0]
  const configUtxos = await lucid.utxosAtWithUnit(configAddr, configUnit)
  const configIn = configUtxos[0]
  const inDatum = Data.from(cUtxo.datum)
  const inYield = inDatum.fields[2]
  const outYield = inYield + yieldAmt
  const inCollateral = cUtxo.assets.lovelace
  console.log(inCollateral)

  console.log(inDatum)

  const newDatum = Data.to(
    new Constr(0, [
      inDatum.fields[0],
      inDatum.fields[1],
      outYield
    ])
  )

  console.log(Data.from(newDatum))

  const withdrawRedeemer = Data.to(
    new Constr(0, [
      [0n]
    ])
  )

  const tx = await lucid
    .newTx()
    .collectFrom(
      [cUtxo],
      depositYieldAction
    )
    .readFrom([configIn])
    .withdraw(depositAddr, 0, withdrawRedeemer)
    .payToContract(
      collateralAddr,
      { inline: newDatum },
      {
        lovelace: (inCollateral - outYield),
        [loanUnit]: 1
      }
    )
    .payToContract(
      yieldAddr,
      { inline: yieldDatum },
      { lovelace: yieldAmt }
    )
    .attachWithdrawalValidator(deposit)
    .attachSpendingValidator(collateralVal)
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}

export async function withdrawYield() {
  const yieldUtxos: UTxO[] = await lucid.utxosAt(yieldAddr)
  const cUtxos: UTxO[] = await lucid.utxosAtWithUnit(collateralAddr, loanUnit)
  const cUtxo: UTxO = cUtxos[0]
  const collateralIn = cUtxo.assets.lovelace
  const configUtxos = await lucid.utxosAtWithUnit(configAddr, configUnit)
  const configIn = configUtxos[0]
  const inDatum = Data.from(cUtxo.datum)
  const inYield = inDatum.fields[2]
  const outYield = 0n

  const newDatum = Data.to(
    new Constr(0, [
      inDatum.fields[0],
      inDatum.fields[1],
      outYield
    ])
  )

  const withdrawRedeemer = Data.to(
    new Constr(0, [
      [0n]
    ])
  )

  const tx = await lucid
    .newTx()
    .collectFrom(
      [cUtxo],
      withdrawYieldAction
    )
    .collectFrom(
      yieldUtxos,
      withdrawYieldAction
    )
    .readFrom([configIn])
    .withdraw(withdrawAddr, 0, withdrawRedeemer)
    .payToContract(
      collateralAddr,
      { inline: newDatum },
      {
        lovelace: (collateralIn + inYield),
        [loanUnit]: 1
      }
    )
    .attachSpendingValidator(collateralVal)
    .attachSpendingValidator(yieldVal)
    .attachWithdrawalValidator(withdraw)
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}