import { mintConfig, burnConfig, updateConfig } from "./offchain/mod.ts"

// deno run --allow-net --allow-read --allow-env config.ts

// // mintConfig
// const mintConfigTx = await mintConfig()
// console.log(`Mint Config Tx: 
//   `, mintConfigTx, `

// NEXT RUN THE ORACLE MINTING TRANSACTION
// `)

// // burnConfig
// const burnConfigTx = await burnConfig()
// console.log("Burn Config Tx: ", burnConfigTx)

// updateConfig
const updateConfigTx = await updateConfig()
console.log(`Update Config Tx: `, updateConfigTx, `

IF YOU CHANGED A WITHDRAWAL VALIDATOR,
REGISTER THE REWARDS ADDRESS IN "./helpers.ts"
  `)