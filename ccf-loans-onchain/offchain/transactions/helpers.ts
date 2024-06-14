import { lucid } from "../blockfrost.ts"
import { closeAddr } from "../validators.ts"
import { ownerAddress } from "../owner.ts"

lucid.selectWalletFromPrivateKey(await Deno.readTextFile("./owner.sk"));

export async function registerStake() {
  const tx = await lucid
    .newTx()
    .registerStake(closeAddr) //balanceAddr | liquidateAddr | closeAddr
    .complete()
  
  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}

export async function splitUtxos() {
  const tx = await lucid
    .newTx()
    .payToAddress(ownerAddress, {lovelace: 100000000n})
    .payToAddress(ownerAddress, {lovelace: 100000000n})
    .payToAddress(ownerAddress, {lovelace: 100000000n})
    .payToAddress(ownerAddress, {lovelace: 100000000n})
    .payToAddress(ownerAddress, {lovelace: 100000000n})
    .complete()

  const signedTx = await tx.sign().complete()

  return signedTx.submit()
}