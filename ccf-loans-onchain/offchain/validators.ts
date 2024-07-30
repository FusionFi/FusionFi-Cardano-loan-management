import {
  SpendingValidator,
  MintingPolicy,
  applyParamsToScript,
  applyDoubleCborEncoding,
  WithdrawalValidator,
} from "https://deno.land/x/lucid@0.10.7/mod.ts";
import * as cbor from "https://deno.land/x/cbor@v1.4.1/index.js";
import { lucid } from "./blockfrost.ts"
import { ownerPKH } from "./owner.ts"

export const configMint = await readConfigMint()
export const configCS = lucid.utils.mintingPolicyToId(configMint)
export const configVal = await readConfigValidator()
export const oracleMint = await readOracleMint()
export const oracleCS = lucid.utils.mintingPolicyToId(oracleMint)
export const oracleVal = await readOracleValidator()
export const interestVal = await readInterestValidator()
export const loanMint = await readLoanMint()
export const loanCS = lucid.utils.mintingPolicyToId(loanMint)
export const loanVal = await readLoanValidator()
export const collateralVal = await readCollateralValidator()
export const rewardsMint = await readRewardsMint()
export const rewardsCS = lucid.utils.mintingPolicyToId(rewardsMint)
export const balance = await readBalanceValidator()
export const liquidate = await readLiquidateValidator()
export const close = await readCloseValidator()
export const repay = await readRepayValidator()

// --- Supporting functions

async function readCollateralValidator(): Promise<SpendingValidator> {
  const validator = JSON.parse(await Deno.readTextFile("plutus.json")).validators[0];
  return {
    type: "PlutusV2",
    script: applyParamsToScript(
      applyDoubleCborEncoding(validator.compiledCode), [configCS]
    ),
  };
}

async function readConfigMint(): Promise<MintingPolicy> {
  const validator = JSON.parse(await Deno.readTextFile("plutus.json")).validators[1];
  return {
    type: "PlutusV2",
    script: applyParamsToScript(
      applyDoubleCborEncoding(validator.compiledCode), [ownerPKH]
    ),
  };
}

async function readInterestValidator(): Promise<SpendingValidator> {
  const validator = JSON.parse(await Deno.readTextFile("plutus.json")).validators[2];
  return {
    type: "PlutusV2",
    script: applyParamsToScript(
      applyDoubleCborEncoding(validator.compiledCode), [oracleCS, ownerPKH]
    ),
  };
}

async function readLoanMint(): Promise<MintingPolicy> {
  const validator = JSON.parse(await Deno.readTextFile("plutus.json")).validators[3];
  return {
    type: "PlutusV2",
    script: applyParamsToScript(
      applyDoubleCborEncoding(validator.compiledCode), [oracleCS, configCS]
    ),
  };
}

async function readLoanValidator(): Promise<SpendingValidator> {
  const validator = JSON.parse(await Deno.readTextFile("plutus.json")).validators[4];
  return {
    type: "PlutusV2",
    script: applyParamsToScript(
      applyDoubleCborEncoding(validator.compiledCode), [configCS]
    ),
  };
}

async function readBalanceValidator(): Promise<WithdrawalValidator> {
  const validator = JSON.parse( await Deno.readTextFile("plutus.json")).validators[5];
  return {
    type: "PlutusV2",
    script: applyParamsToScript(
      applyDoubleCborEncoding(validator.compiledCode), [oracleCS, configCS]
    ),
  }
}

async function readCloseValidator(): Promise<WithdrawalValidator> {
  const validator = JSON.parse( await Deno.readTextFile("plutus.json")).validators[6];
  return {
    type: "PlutusV2",
    script: applyParamsToScript(
      applyDoubleCborEncoding(validator.compiledCode), [loanCS, oracleCS]
    ),
  }
}

async function readConfigValidator(): Promise<SpendingValidator> {
  const validator = JSON.parse(await Deno.readTextFile("plutus.json")).validators[7];
  return {
    type: "PlutusV2",
    script: applyParamsToScript(
      applyDoubleCborEncoding(validator.compiledCode), [ownerPKH, configCS]
    ),
  };
}

async function readLiquidateValidator(): Promise<WithdrawalValidator> {
  const validator = JSON.parse( await Deno.readTextFile("plutus.json")).validators[8];
  return {
    type: "PlutusV2",
    script: applyParamsToScript(
      applyDoubleCborEncoding(validator.compiledCode), [oracleCS, configCS]
    ),
  }
}

async function readRepayValidator(): Promise<WithdrawalValidator> {
  const validator = JSON.parse( await Deno.readTextFile("plutus.json")).validators[9];
  return {
    type: "PlutusV2",
    script: applyParamsToScript(
      applyDoubleCborEncoding(validator.compiledCode), [oracleCS, configCS]
    ),
  }
}

async function readOracleMint(): Promise<MintingPolicy> {
  const validator = JSON.parse(await Deno.readTextFile("plutus.json")).validators[10]
  return {
    type: "PlutusV2",
    script: applyParamsToScript(
      applyDoubleCborEncoding(validator.compiledCode), [ownerPKH, configCS]
    ),
  }
}

async function readOracleValidator(): Promise<SpendingValidator> {
  const validator = JSON.parse(await Deno.readTextFile("plutus.json")).validators[11];
  return {
    type: "PlutusV2",
    script: applyParamsToScript(
      applyDoubleCborEncoding(validator.compiledCode), [ownerPKH, oracleCS]
    ),
  };
}

async function readRewardsMint(): Promise<MintingPolicy> {
  const validator = JSON.parse(await Deno.readTextFile("plutus.json")).validators[12];
  return {
    type: "PlutusV2",
    script: applyParamsToScript(
      applyDoubleCborEncoding(validator.compiledCode), [ownerPKH, configCS, loanCS]
    ),
  };
}

// Validator Addresses //

export const oracleAddr = lucid.utils.validatorToAddress(oracleVal)
export const loanAddr = lucid.utils.validatorToAddress(loanVal)
export const collateralAddr = lucid.utils.validatorToAddress(collateralVal)
export const configAddr = lucid.utils.validatorToAddress(configVal)
export const balanceAddr = lucid.utils.validatorToRewardAddress(balance)
export const liquidateAddr = lucid.utils.validatorToRewardAddress(liquidate)
export const closeAddr = lucid.utils.validatorToRewardAddress(close)
export const repayAddr = lucid.utils.validatorToRewardAddress(repay)
export const interestAddr = lucid.utils.validatorToAddress(interestVal)

// Validator Hashes //

export const oracleHash = await lucid.utils.validatorToScriptHash(oracleVal)
export const loanHash = await lucid.utils.validatorToScriptHash(loanVal)
export const configHash = await lucid.utils.validatorToScriptHash(configVal)
export const collateralHash = await lucid.utils.validatorToScriptHash(collateralVal)
export const balanceHash = await lucid.utils.validatorToScriptHash(balance)
export const liquidateHash = await lucid.utils.validatorToScriptHash(liquidate)
export const closeHash = await lucid.utils.validatorToScriptHash(close)
export const repayHash = await lucid.utils.validatorToScriptHash(repay)
export const interestHash = await lucid.utils.validatorToScriptHash(interestVal)

export const loanHashz = [balanceHash]
export const collateralHashz = [balanceHash, liquidateHash, closeHash, repayHash]