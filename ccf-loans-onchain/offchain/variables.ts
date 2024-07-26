import { fromText, fromUnit, toUnit, } from "https://deno.land/x/lucid@0.10.7/mod.ts" ;
import { configCS } from "./validators.ts"

export const price1 = 500n
export const price2 = 550n
export const price3 = 600n
export const price4 = 450n
export const price5 = 400n
export const price6 = 265n
export const price7 = 50n

export const base = 55n 
export const optimal = 70n 
export const slope1 = 40n
export const slope2 = 300n
export const supply = 1000000n
export const borrowed = 200000n

export const collateral = fromText("ADA")
export const collateralAmt = 10n
export const loanCurrency = fromText("USDT")
export const loanAmt = 5n
export const timestamp = BigInt(new Date().getTime())
export const interest = 15n
export const fee = 2n
export const term = 0n
export const rewards = 5n

export const oracleUnit = "e75c32da3aad61874dcc7f3a47a8c534fa60eebdccd974f19763f6221d44314e9af788196f468071823b69"

export const oracleTn = fromUnit(oracleUnit).assetName

export const configTN = fromText("") 
export const configUnit = toUnit(configCS, configTN)

export const loanUnit = "bcb4b7cc49cdfa05d6964c79e62b1bb4df59172c7010f4e55b1f13cff4aa85f8406f6bd163f504438d8126"

export const interestPayAddr = "addr_test1vr4m7cd94yhymrwcmgs2k6zs00jql9d075ms0dgxjv2tuxqjy82wz"

export function interestCalc(
  base,
  optimal,
  slope1,
  slope2,
  supply,
  borrowed,
) {
  const utilisation = borrowed / supply
  if (utilisation <= optimal) {
    const ratio = utilisation / optimal 
    const variable = ratio * slope1 
    const combined = base + variable
    return combined
  } else {
    const slope = base + slope1 
    const nominator = utilisation - optimal 
    const denominator = 100 - optimal 
    const ratio = nominator / denominator 
    const variableFee = ratio * slope2 
    const combined = slope + variableFee
    return combined
  }
}