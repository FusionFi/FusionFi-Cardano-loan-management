import { mintOracle, oracleClose, oAutoUpdate, oManualUpdate, oracleDatum1, oracleDatum2, oracleDatum3, oracleDatum4, updateInterest } from "./offchain/mod.ts"

// deno run --allow-net --allow-read --allow-env oracle.ts

// mintOracle 
const mintOracleTx = await mintOracle()
console.log(`Mint Oracle Tx: 
  https://preview.cardanoscan.io/transaction/${mintOracleTx}

SAVE THE ORACLE UNIT IN variables.ts
  Or the other transactions will not work!

NOW YOU HAVE A PRICE FEED HERE ARE YOUR OPTIONS:
  -> Update The Oracle with oracle.ts
  -> Mint A Loan with loan.ts
`)

// // closeOracle
// const closeOracleTx = await oracleClose()
// console.log(`Burned Oracle Tx: 
//   https://preview.cardanoscan.io/transaction/${closeOracleTx}

// YOU'VE CLOSED YOUR ORACLE!
//   -> Mint a new one
//   -> burn your ConfigToken and close the Dapp
// `)

// // updateOracle
// const updateOracleTX = await oAutoUpdate()
// console.log(`Update Oracle Tx: 
//   https://preview.cardanoscan.io/transaction/${updateOracleTX}
  
// THE ORACLE HAS UPDATED!
//   -> You can update a loan in loan.ts
//   `)

// // updateOracleManual
// const updateOracleManualTx = await oManualUpdate()
// console.log(`Update Oracle Manual Tx: 
//   https://preview.cardanoscan.io/transaction/${updateOracleManualTx}

// THE ORACLE HAS UPDATED!
//   -> You can update a loan in loan.ts
// `)

// // updateInterest
// const updateInterestTx = await updateInterest()
// console.log(`Update Interest Rates Tx:
//   https://preview.cardanoscan.io/transaction/${updateInterestTx}

// THE INTEREST RATES HAVE BEEN UPDATED!
//   -> You can now repay and test with loan.ts
//   `)