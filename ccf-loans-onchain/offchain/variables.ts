import { fromText, fromUnit, toUnit, } from "https://deno.land/x/lucid@0.10.7/mod.ts";
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
export const collateralAmt = 200n
export const loanCurrency = fromText("USDT")
export const loanAmt = 100n
export const timestamp = BigInt(new Date().getTime())
export const interest = 15n
export const fee = 2n
export const term = 0n
export const rewards = 100n
export const yieldDatumText = fromText("loan")

export const oracleUnit = "eb794aac8cdc0cc937d712f1cea95713d7244f6d42a95dcb7b9201989cf8f06b8555893a1df9cce9375733"

export const oracleTn = fromUnit(oracleUnit).assetName

export const configTN = fromText("")
export const configUnit = toUnit(configCS, configTN)

// $100 loan test for interest payments
export const loanUnit = "a1872cb404df1918654015c9ec240b0d0866d688091da03114391508d29dda177d877fc3456e5ce6d2dcae"

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