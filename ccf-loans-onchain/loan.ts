import { mintLoan, balanceLoan, liquidateLoan, repayLoan, burnLoan, loanAmt, rewards, term, timestamp, oracleTn } from "./offchain/mod.ts"

// deno run --allow-net --allow-read --allow-env loan.ts

// mintLoan
const mintLoanTx = await mintLoan()
console.log(`Mint Loan Tx: 
  `, mintLoanTx, `

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
console.log("Balance Loan Tx: ", balanceLoanTx)

// liquidateLoan -> Done
const liquidateLoanTx = await liquidateLoan()
console.log("Liquidate Loan Tx: ", liquidateLoanTx)

// repayLoan -> Done
const repayLoanTx = await repayLoan()
console.log("Repay Loan Tx: ", repayLoanTx)

// burnLoan
const burnLoanTx = await burnLoan()
console.log("Burn Loan Tx: ", burnLoanTx)