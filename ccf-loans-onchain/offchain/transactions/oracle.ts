import { toHex, toUnit, UTxO, } from "https://deno.land/x/lucid@0.10.7/mod.ts";
import * as cbor from "https://deno.land/x/cbor@v1.4.1/index.js";
import { lucid } from "../blockfrost.ts"
import { oracleDatum1 } from "../datums.ts";
import { ownerAddress, ownerPKH } from "../owner.ts";
import { oracleMintAction, oracleUpdateAction, oracleCloseAction, oracleBurnAction } from "../redeemers.ts";
import { configAddr, oracleCS, oracleMint, oracleAddr, oracleVal } from "../validators.ts";
import { configUnit, oracleUnit } from "../variables.ts";

lucid.selectWalletFromPrivateKey(await Deno.readTextFile("./owner.sk"));

export async function mintOracle() {
  console.log(`ORACLE TRANSACTION
`)
  const utxos: [UTxO] = await lucid.utxosAt(ownerAddress)
  const utxo: UTxO = utxos[0]
  // console.log(utxo)
  const configUtxos: [UTxO] = await lucid.utxosAtWithUnit(configAddr, configUnit)
  const configIn: UTxO = configUtxos[0]
  // console.log(configIn)
  const oracleTN = utxo.txHash.slice(0, 30).concat(toHex(utxo.outputIndex))
  console.log("Oracle Token Name: ", oracleTN)
  const oracleUnit = toUnit(oracleCS, oracleTN)
  console.log("Oracle Unit: ", oracleUnit)
  
  const tx = await lucid
    .newTx()
    .collectFrom([utxo])
    .readFrom([configIn])
    .mintAssets({
      [oracleUnit]: 1,
    }, oracleMintAction)
    .attachMintingPolicy(oracleMint)
    .payToContract(
      oracleAddr, 
      { inline: oracleDatum1 }, 
      { [oracleUnit]: 1 }
    )
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}

// Oracle Update Functions //

export async function oAutoUpdate() {
  console.log(`ORACLE TRANSACTION
    `)
  const utxos: UTxO[] = await lucid.utxosAtWithUnit(oracleAddr, oracleUnit)
  const utxo: UTxO = utxos[0]
  console.log(`Oracle Input UTxO: 
  `, utxo, `
  `)

  const tx = await lucid
    .newTx()
    .collectFrom([utxo], oracleUpdateAction)
    .payToContract(
      oracleAddr, 
      { inline: oracleDatum1 }, 
      { [oracleUnit]: 1 }
    )
    .attachSpendingValidator(oracleVal)
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()

}

export async function oManualUpdate() {
  console.log(`ORACLE TRANSACTION
    `)
  const utxos: [UTxO] = await lucid.utxosAtWithUnit(oracleAddr, oracleUnit)
  const utxo: UTxO = utxos[0]

  const tx = await lucid
    .newTx()
    .collectFrom([utxo], oracleUpdateAction)
    .payToContract(
      oracleAddr, 
      { inline: oracleDatum3 }, 
      { [oracleUnit]: 1 }
    )
    .attachSpendingValidator(oracleVal)
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}

export async function oracleClose() {
  console.log(`ORACLE TRANSACTION
    `)

  const utxos: UTxO[] = await lucid.utxosAtWithUnit(oracleAddr, oracleUnit)
  const utxo: UTxO = utxos[0]
  console.log(utxo)

  const tx = await lucid
    .newTx()
    .collectFrom([utxo], oracleCloseAction)
    .attachSpendingValidator(oracleVal)
    .mintAssets({
      [oracleUnit]: -1,
    }, oracleBurnAction)
    .attachMintingPolicy(oracleMint)
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}
