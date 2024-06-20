import { mintLoan, balanceLoan, liquidateLoan, repayLoan, burnLoan, loanAmt, rewards, term, timestamp, oracleTn } from "./offchain/mod.ts"

// deno run --allow-net --allow-read --allow-env loan.ts

// mintLoan
const mintLoanTx = await mintLoan()
console.log(`Mint Loan Tx: 
  https://preview.cardanoscan.io/`, mintLoanTx, `

Loan Datum: 
  Amt: `, loanAmt, `
  Rewards: `, rewards, `
  Term: `, term, `
  Timestamp: `, timestamp, `
  Oracle: `, oracleTn, `

NOW YOU CAN BALANCE, LIQUIDATE AND CLOSE THE LOAN
SAVE YOUR LOAN UNIT IN "./offchain/variables.ts"

`)

// balanceLoan -> Done
const balanceLoanTx = await balanceLoan()
console.log(`Balance Loan Tx: 
  https://preview.cardanoscan.io/`, balanceLoanTx, `

YOU HAVE BALANCED YOUR LOAN!
  -> Update Oracle
  -> Repay or Liquidate Loan
  `)

// liquidateLoan -> Done
const liquidateLoanTx = await liquidateLoan()
console.log(`Liquidate Loan Tx: 
  https://preview.cardanoscan.io/`, liquidateLoanTx, `
  
YOUR LOAN HAS BEEN LIQUIDATED!
  -> You can burn your loan token
  -> Mint new Loans
  -> Close Oracle and Config
  `)

// repayLoan -> Done
const repayLoanTx = await repayLoan()
console.log(`Repay Loan Tx: 
  https://preview.cardanoscan.io/`, repayLoanTx, `

YOUR LOAN HAS BEEON REPAID, YOU CAN NOW BURN THE LOAN TOKEN
  -> burnLoanTx()
  `)

// burnLoan
const burnLoanTx = await burnLoan()
console.log(`Burn Loan Tx: 
  https://preview.cardanoscan.io/`, burnLoanTx, `

YOU HAVE CLOSED YOUR LOAN!
  -> Close Oracles and Config
  -> Mint new Loans and Oracles
  `)