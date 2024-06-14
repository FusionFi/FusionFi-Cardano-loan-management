import { splitUtxos, registerStake } from "./offchain/mod.ts"

// deno run --allow-net --allow-read --allow-env helpers.ts

// Make Wallet UTxOs
const splitUtxosTx = await splitUtxos()
console.log(`Split Tx: 
  `, splitUtxosTx, `
`)

// register stake address
const registerAddTx = await registerStake()
console.log("Register Stake Address: ", registerAddTx)

