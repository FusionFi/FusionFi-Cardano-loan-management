import { Constr, Data, } from "https://deno.land/x/lucid@0.10.7/mod.ts";
import { loanHashz, collateralHashz, loanHash, collateralHash, rewardsCS, rewardsMint, oracleHash, balanceHash, liquidateHash, closeHash, interestHash } from "./validators.ts"
import { loanAmt, rewards, term, timestamp, price1, price2, price3, price4, price5, price6, price7, interest, fee, loanCurrency, oracleTn, collateralAmt, base, borrowed, optimal, slope1, slope2, supply } from "./variables.ts"

export const mintLoanAction = Data.to(new Constr(0, [loanAmt, rewards, term, timestamp]))
export const burnLoanAction = Data.to(new Constr(1, []))

export const configUpdateAction = Data.to(new Constr(0, [
  loanHash,
  collateralHash,
  rewardsCS,
  oracleHash,
  interestHash,
  collateralHashz,
]))

export const configCloseAction = Data.to(new Constr(1, []))

export const oracleUpdateAction = Data.to(
  new Constr(0, [
    price1, // change this to match oracleDatum Output or it will fail
    timestamp,
    supply,
    borrowed,
  ]))

export const oracleCloseAction = Data.to(new Constr(1, []))

export const oracleMintAction = Data.to(new Constr(0, [
  price1,
  timestamp,
  loanCurrency,
  supply,
  borrowed,
  base,
  optimal,
  slope1,
  slope2,
  term,
]))

export const oracleBurnAction = Data.to(new Constr(1, []))
export const loanBalanceAction = Data.to(new Constr(0, [0n]))
export const loanLiquidateAction = Data.to(new Constr(0, [1n]))
export const loanCloseAction = Data.to(new Constr(0, [2n]))
export const loanRepayAction = Data.to(new Constr(0, [3n]))
export const rewardsMintAction = Data.to(new Constr(0, []))
export const rewardsBurnAction = Data.to(new Constr(1, []))