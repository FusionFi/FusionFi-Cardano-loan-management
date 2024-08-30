import { Data, UTxO } from "https://deno.land/x/lucid@0.10.7/mod.ts";
import * as cbor from "https://deno.land/x/cbor@v1.4.1/index.js";
import { lucid } from "../blockfrost.ts"
import { ownerAddress, ownerPKH } from "../owner.ts"
import { configDatum } from "../datums.ts"
import { configCloseAction, configUpdateAction } from "../redeemers.ts"
import { configAddr, configMint, configVal } from "../validators.ts"
import { configUnit } from "../variables.ts";

lucid.selectWalletFromPrivateKey(await Deno.readTextFile("./owner.sk"));

export async function mintConfig() {
  console.log(`CONFIGURATION TRANSACTION
`)
  const utxos: [UTxO] = await lucid.utxosAt(ownerAddress)
  const utxo: UTxO = utxos[0]

  const tx = await lucid
    .newTx()
    .collectFrom([utxo])
    .mintAssets({
      [configUnit]: 1n,
    }, configUpdateAction)
    .attachMintingPolicy(configMint)
    .payToContract(
      configAddr,
      { inline: configDatum },
      { [configUnit]: 1n }
    )
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}

export async function updateConfig() {
  console.log(`CONFIGURATION TRANSACTION
`)
  const utxos: [UTxO] = await lucid.utxosAtWithUnit(configAddr, configUnit)
  const utxo: UTxO = utxos[0]

  console.log(`Config Datum: 
    `, Data.from(configDatum).fields, `
  `)

  const tx = await lucid
    .newTx()
    .collectFrom([utxo], configUpdateAction)
    .attachSpendingValidator(configVal)
    .payToContract(
      configAddr,
      { inline: configDatum },
      { [configUnit]: 1n }
    )
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}

export async function burnConfig() {
  console.log(`CONFIGURATION TRANSACTION
`)
  const utxos: [UTxO] = await lucid.utxosAtWithUnit(configAddr, configUnit)
  const utxo: UTxO = utxos[0]

  const tx = await lucid
    .newTx()
    .collectFrom([utxo], configCloseAction)
    .mintAssets({
      [configUnit]: -1,
    }, configCloseAction)
    .attachMintingPolicy(configMint)
    .attachSpendingValidator(configVal)
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}