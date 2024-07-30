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

export const oracleUnit = "40da844f41c3204a770e6c7f082eab5f9bfed43384650dccf990b30d1cb0a8c6f198743ef35661381d0575"

export const oracleTn = fromUnit(oracleUnit).assetName

export const configTN = fromText("") 
export const configUnit = toUnit(configCS, configTN)

export const loanUnit = "e680537242d8e3a6561060004690486a6148de8d040eab256d6300faee7fbfdaac034c20f8e50a7382fd2a"

export const interestPayAddr = "addr_test1vr4m7cd94yhymrwcmgs2k6zs00jql9d075ms0dgxjv2tuxqjy82wz"

export function interestCalc(
  base: number,
  optimal: number,
  slope1: number,
  slope2: number,
  supply: number,
  borrowed: number,
) {
  const utilisation = borrowed / supply
  console.log(`utilisation: ${utilisation}`)
  if (utilisation <= optimal) {
    const ratio = utilisation / optimal 
    console.log(`ratio: ${ratio}`)
    const variable = ratio * slope1 
    console.log(`variable: ${variable}`)
    const combined = base + variable
    console.log(`combined: ${combined}`)
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