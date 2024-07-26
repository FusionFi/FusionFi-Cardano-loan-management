import { mintConfig, burnConfig, updateConfig } from "./offchain/mod.ts"

// deno run --allow-net --allow-read --allow-env config.ts

// // mintConfig
// const mintConfigTx = await mintConfig()
// console.log(`Mint Config Tx: 
//   https://preview.cardanoscan.io/transaction/${mintConfigTx}

// NEXT RUN THE ORACLE MINTING TRANSACTION:
//   -> Uncomment mintOracleTx()
//   -> You can edit the variables
//   -> deno run --allow-net --allow-read --allow-env oracle.ts
// `)

// burnConfig
const burnConfigTx = await burnConfig()
console.log(`Burn Config Tx: 
  https://preview.cardanoscan.io/transaction/${burnConfigTx} 
  
YOU HAVE NOW CLOSED THE DAPP!

Thanks for testing with STOIC @ EmurgoLabs! =]
  `)

// // updateConfig
// const updateConfigTx = await updateConfig()
// console.log(`Update Config Tx: 
//   https://preview.cardanoscan.io/transaction/${updateConfigTx}

// IF YOU CHANGED A WITHDRAWAL VALIDATOR,
// REGISTER THE REWARDS ADDRESS IN "./helpers.ts"
//   -> Uncomment RegisterAddTx()
//   -> deno run --allow-net --allow-read --allow-env helpers.ts

// OTHERWISE YOU CAN CONTINUE MINTING/UPDATING LOANS:
//   -> See loan.ts && oracle.ts
//   `)