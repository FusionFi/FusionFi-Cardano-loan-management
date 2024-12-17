import { mintLoan, closeLoan, balanceLoan, liquidateLoan, repayLoan, burnLoan, loanAmt, rewards, term, timestamp, oracleTn, depositYield, collateralAddr, collateralHash, withdrawYield } from "./offchain/mod.ts"

// deno run --allow-net --allow-read --allow-env loan.ts

// // mintLoan
// const mintLoanTx = await mintLoan()
// console.log(`Mint Loan Tx: 
//   https://preview.cardanoscan.io/transaction/${mintLoanTx}

// Loan Datum: 
//   Amt: `, loanAmt, `
//   Rewards: `, rewards, `
//   Term: `, term, `
//   Timestamp: `, timestamp, `
//   Oracle: `, oracleTn, `

// SAVE YOUR LOAN UNIT IN "./offchain/variables.ts"
//   or you will not be able to run the other transactions!

// NOW YOU CAN BALANCE, LIQUIDATE AND CLOSE THE LOAN

// `)

// // balanceLoan -> Done
// const balanceLoanTx = await balanceLoan()
// console.log(`Balance Loan Tx: 
//   https://preview.cardanoscan.io/transaction/${balanceLoanTx}

// YOU HAVE BALANCED YOUR LOAN!
//   -> Update Oracle
//   -> Repay or Liquidate Loan
//   `)

// // liquidateLoan -> Done
// const liquidateLoanTx = await liquidateLoan()
// console.log(`Liquidate Loan Tx: 
//   https://preview.cardanoscan.io/transaction/${liquidateLoanTx}

// YOUR LOAN HAS BEEN LIQUIDATED!
//   -> You can burn your loan token
//   -> Mint new Loans
//   -> Close Oracle and Config
//   `)

// // repayLoan -> Done
// const repayLoanTx = await repayLoan()
// console.log(`Repay Loan Tx: 
//   https://preview.cardanoscan.io/transaction/${repayLoanTx}

// YOUR LOAN HAS BEEON REPAID, YOU CAN NOW BURN THE LOAN TOKEN
//   -> burnLoanTx()
//   `)

// // depositYield -> Wip

// const depositYieldTx = await depositYield()
// console.log(`Deposit Yield Tx: 
//   https://preview.cardanoscan.io/transaction/${depositYieldTx}

// YOUR LOAN HAS BEEON REPAID, YOU CAN NOW BURN THE LOAN TOKEN
//   -> burnLoanTx()
//   `)

// // withdrawYield -> Wip
// const withdrawYieldTx = await withdrawYield()
// console.log(`Withdraw Yield Tx: 
//   https://preview.cardanoscan.io/transaction/${withdrawYieldTx}

// YOUR LOAN HAS BEEON REPAID, YOU CAN NOW BURN THE LOAN TOKEN
//   -> burnLoanTx()
//   `)

// // burnLoan
// const burnLoanTx = await burnLoan()
// console.log(`Burn Loan Tx: 
//   https://preview.cardanoscan.io/transaction/${burnLoanTx}

// YOU HAVE CLOSED YOUR LOAN!
//   -> Close Oracles and Config
//   -> Mint new Loans and Oracles
//   `)

// close W Rewards 
const closeLoanTx = await closeLoan()
console.log(`Close Loan Tx:
  https://preview.cardanoscan.io/transaction/${closeLoanTx}
  
YOU HAVE CLOSED YOUR LOAN!
  -> You recieved ${loanAmt} rewards tokens!
  -> You can Mint more Loans or close the dapp
  `)