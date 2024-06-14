import { Constr, Data, } from "https://deno.land/x/lucid@0.10.7/mod.ts";
import { loanHashz, collateralHashz, loanHash, collateralHash, rewardsCS, rewardsMint, oracleHash, balanceHash, liquidateHash, closeHash } from "./validators.ts"
import { loanAmt, rewards, term, timestamp, price1, interest, fee, loanCurrency, oracleTn, collateralAmt } from "./variables.ts"

export const mintLoanAction = Data.to(new Constr(0, [loanAmt, rewards, term, timestamp]))
export const burnLoanAction = Data.to(new Constr(1, []))

export const configUpdateAction = Data.to(new Constr(0, [
  loanHash,
  collateralHash,
  rewardsCS,
  oracleHash,
  loanHashz,
  collateralHashz,
]))

export const configCloseAction = Data.to(new Constr(1, []))

export const oracleUpdateAction = Data.to(
  new Constr(0, [
    price1, // change this to match oracleDatum Output or it will fail
    timestamp,
    interest,
    fee,
  ]))

export const oracleCloseAction = Data.to(new Constr(1, []))

export const oracleMintAction = Data.to(new Constr(0, []))
export const oracleBurnAction = Data.to(new Constr(1, []))
export const loanBalanceAction = Data.to(new Constr(0, [0n]))
export const loanLiquidateAction = Data.to(new Constr(0, [1n]))
export const loanCloseAction = Data.to(new Constr(0, [2n]))

export const rewardsMintAction = Data.to(new Constr(0, []))
export const rewardsBurnAction = Data.to(new Constr(1, []))