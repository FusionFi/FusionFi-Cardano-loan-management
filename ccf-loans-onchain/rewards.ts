import { mintRewards, burnRewards } from "./offchain/mod.ts"

// deno run --allow-net --allow-read --allow-env rewards.ts

// mintRewards
const mintRewardsTx = await mintRewards()
console.log(`Mint Rewards Tx: 
  https://preview.cardanoscan.io/transaction/${mintRewardsTx}
  
  
  `)

// burnRewards
const burnRewardsTx = await burnRewards()
console.log(`Burn Rewards Tx: 
  https://preview.cardanoscan.io/transaction/${burnRewardsTx}
  
  
  `)