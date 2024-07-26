import { Constr, Data, } from "https://deno.land/x/lucid@0.10.7/mod.ts";
import { loanHashz, collateralHashz, loanHash, collateralHash, rewardsCS, oracleHash, interestHash, } from "./validators.ts"
import { loanAmt, rewards, term, timestamp, price1, price2, price3, price4, price5, price6, interest, fee, loanCurrency, oracleTn, collateralAmt, price7, base, optimal, slope1, slope2, borrowed, supply } from "./variables.ts"

export const configDatum = Data.to(new Constr(0, [
  loanHash,
  collateralHash,
  rewardsCS,
  oracleHash,
  interestHash,
  collateralHashz,
]))

export const oracleDatum1 = Data.to(new Constr(0, [price1, timestamp, loanCurrency, supply, borrowed]))
export const oracleDatum2 = Data.to(new Constr(0, [price2, timestamp, loanCurrency, supply, borrowed]))
export const oracleDatum3 = Data.to(new Constr(0, [price3, timestamp, loanCurrency, supply, borrowed]))
export const oracleDatum4 = Data.to(new Constr(0, [price4, timestamp, loanCurrency, supply, borrowed]))
export const oracleDatum5 = Data.to(new Constr(0, [price5, timestamp, loanCurrency, supply, borrowed]))
export const oracleDatum6 = Data.to(new Constr(0, [price6, timestamp, loanCurrency, supply, borrowed]))
export const oracleDatum7 = Data.to(new Constr(0, [price7, timestamp, loanCurrency, supply, borrowed]))

export const interestDatum = Data.to(new Constr(0, [base, optimal, slope1, slope2, term]))

export const loanDatum = Data.to(
  new Constr(0, [
    loanAmt,  
    rewards, 
    term, 
    timestamp, 
    oracleTn
  ]))

export const collateralDatum = Data.to(
  new Constr(0, [
    collateralAmt,
    timestamp
  ])
)