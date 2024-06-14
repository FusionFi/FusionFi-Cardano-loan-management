import { fromText, fromUnit, toUnit, } from "https://deno.land/x/lucid@0.10.7/mod.ts";
import { configCS } from "./validators.ts"

export const price1 = 500n
export const price2 = 550n
export const price3 = 600n
export const price4 = 450n
export const price5 = 400n
export const price6 = 265n

export const collateral = fromText("ADA")
export const collateralAmt = 10n
export const loanCurrency = fromText("USDT")
export const loanAmt = 5n
export const timestamp = BigInt(new Date().getTime())
export const interest = 15n
export const fee = 2n
export const term = 0n
export const rewards = 5n

export const oracleUnit = "e75c32da3aad61874dcc7f3a47a8c534fa60eebdccd974f19763f622ea2ccf3a3bb63238e9f4d4e03c82a6"

export const oracleTn = fromUnit(oracleUnit).assetName

export const configTN = fromText("") //"227c1b757b4b17515244f1614b402900"
export const configUnit = toUnit(configCS, configTN)

export const loanUnit = "bcb4b7cc49cdfa05d6964c79e62b1bb4df59172c7010f4e55b1f13cfdddbc457de675964a37f0fc52dd3b0"
