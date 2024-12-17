import { splitUtxos, registerStake } from "./offchain/mod.ts"

// deno run --allow-net --allow-read --allow-env helpers.ts

// // Make Wallet UTxOs
// const splitUtxosTx = await splitUtxos()
// console.log(`Split Tx: 
//   https://preview.cardanoscan.io/transaction/${splitUtxosTx}

// You will now have several ADA-Only UTXOs to use for testing
//   `)

// register stake address
const registerAddTx = await registerStake()
console.log(`Register Stake Address: 
  https://preview.cardanoscan.io/transaction/${registerAddTx}

Now your merkel validators are ready you can continue with your tests
  -> Mint a Loan
  -> Update your Oracle
  `)

