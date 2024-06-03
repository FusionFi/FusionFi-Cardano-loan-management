import {
  Blockfrost,
  C,
  Constr,
  Data,
  Lucid,
  SpendingValidator,
  MintingPolicy,
  applyParamsToScript,
  applyDoubleCborEncoding,
  TxHash,
  fromHex,
  fromText,
  toHex,
  toUnit,
  UTxO,
  utxosAtWithUnit,
  utxosAt,
  WithdrawalValidator,
} from "https://deno.land/x/lucid@0.10.7/mod.ts";
import * as cbor from "https://deno.land/x/cbor@v1.4.1/index.js";

// deno run --allow-net --allow-read --allow-env full.ts

// TODO: This transaction code is WIP not complete


const BLOCKFROST = "API_KEY"
 
const lucid = await Lucid.new(
  new Blockfrost(
    "https://cardano-preview.blockfrost.io/api/v0",
    BLOCKFROST,
  ),
  "Preview",
);

// ---------------------------------------- //

// Contract & Wallet Setup //

// ---------------------------------------- //

lucid.selectWalletFromPrivateKey(await Deno.readTextFile("./owner.sk"));
 
const ownerPKH = lucid.utils.getAddressDetails(await Deno.readTextFile("owner.addr"))
.paymentCredential.hash;

const oracleMint = await readOracleMint()
const oracleCS = lucid.utils.mintingPolicyToId(oracleMint)
const oracleVal = await readOracleValidator()
const configMint = await readConfigMint()
const configCS = lucid.utils.mintingPolicyToId(configMint)
const configVal = await readConfigValidator()
const loanMint = await readLoanMint()
const loanCS = lucid.utils.mintingPolicyToId(loanMint)
const loanVal = await readLoanValidator()
const collateralVal = await readCollateralValidator()
const rewardsMint = await readRewardsMint()
const rewardsCS = lucid.utils.mintingPolicyToId(rewardsMint)
const balance = await readBalanceValidator()
const liquidate = await readLiquidateValidator()
const close = await readCloseValidator()

// --- Supporting functions

async function readCollateralValidator(): Promise<SpendingValidator> {
  const validator = JSON.parse(await Deno.readTextFile("plutus.json")).validators[0];
  return {
    type: "PlutusV2",
    script: applyParamsToScript(
      applyDoubleCborEncoding(validator.compiledCode), [oracleCS, loanCS, configCS]
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

async function readLoanMint(): Promise<MintingPolicy> {
  const validator = JSON.parse(await Deno.readTextFile("plutus.json")).validators[2];
  return {
    type: "PlutusV2",
    script: applyParamsToScript(
      applyDoubleCborEncoding(validator.compiledCode), [oracleCS, configCS]
    ),
  };
}

async function readLoanValidator(): Promise<SpendingValidator> {
  const validator = JSON.parse(await Deno.readTextFile("plutus.json")).validators[3];
  return {
    type: "PlutusV2",
    script: applyParamsToScript(
      applyDoubleCborEncoding(validator.compiledCode), [oracleCS, loanCS, configCS]
    ),
  };
}

async function readBalanceValidator(): Promise<WithdrawalValidator> {
  const validator = JSON.parse( await Deno.readTextFile("plutus.json")).validators[4];
  return {
    type: "PlutusV2",
    script: applyParamsToScript(
      applyDoubleCborEncoding(validator.compiledCode), [oracleCS, configCS]
    ),
  }
}

async function readCloseValidator(): Promise<WithdrawalValidator> {
  const validator = JSON.parse( await Deno.readTextFile("plutus.json")).validators[5];
  return {
    type: "PlutusV2",
    script: applyParamsToScript(
      applyDoubleCborEncoding(validator.compiledCode), [loanCS, oracleCS]
    ),
  }
}

async function readConfigValidator(): Promise<SpendingValidator> {
  const validator = JSON.parse(await Deno.readTextFile("plutus.json")).validators[6];
  return {
    type: "PlutusV2",
    script: applyParamsToScript(
      applyDoubleCborEncoding(validator.compiledCode), [ownerPKH, configCS]
    ),
  };
}

async function readLiquidateValidator(): Promise<WithdrawalValidator> {
  const validator = JSON.parse( await Deno.readTextFile("plutus.json")).validators[7];
  return {
    type: "PlutusV2",
    script: applyParamsToScript(
      applyDoubleCborEncoding(validator.compiledCode), [oracleCS, configCS]
    ),
  }
}

async function readOracleMint(): Promise<MintingPolicy> {
  const validator = JSON.parse(await Deno.readTextFile("plutus.json")).validators[8]
  return {
    type: "PlutusV2",
    script: applyParamsToScript(
      applyDoubleCborEncoding(validator.compiledCode), [ownerPKH]
    ),
  }
}

async function readOracleValidator(): Promise<SpendingValidator> {
  const validator = JSON.parse(await Deno.readTextFile("plutus.json")).validators[9];
  return {
    type: "PlutusV2",
    script: applyParamsToScript(
      applyDoubleCborEncoding(validator.compiledCode), [ownerPKH, oracleCS]
    ),
  };
}

async function readRewardsMint(): Promise<MintingPolicy> {
  const validator = JSON.parse(await Deno.readTextFile("plutus.json")).validators[10];
  return {
    type: "PlutusV2",
    script: applyParamsToScript(
      applyDoubleCborEncoding(validator.compiledCode), [ownerPKH, configCS, loanCS]
    ),
  };
}

const ownerAddress = await Deno.readTextFile("./owner.addr");

const userPKH =
  lucid.utils.getAddressDetails(await Deno.readTextFile("beneficiary.addr"))
.paymentCredential.hash;

const userAddress = await Deno.readTextFile("./beneficiary.addr");

// ---------------------------------------- //

// Transaction Data //

// ---------------------------------------- //

const price1 = 0.5
const price2 = 0.55
const price3 = 0.6
const price4 = 0.45
const price5 = 0.4
const price6 = 0.265

// const collateral = "ADA"
const collateralAmt = 1000n
const loanCurrency = "USDT"
const loanAmt = 500n
const timestamp = new Date().getTime()
const interest = 15n
const fee = 2n
const term = 12n
const rewards = 500n

const oracleAddr = lucid.utils.validatorToAddress(oracleVal)
const loanAddr = lucid.utils.validatorToAddress(loanVal)
const collateralAddr = lucid.utils.validatorToAddress(collateralVal)
const configAddr = lucid.utils.validatorToAddress(configVal)

const oracleHash = await lucid.getAddressDetails(oAddr).paymentCredential.hash
const loanHash = await lucid.getAddressDetails(lAddr).paymentCredential.hash
const configHash = await lucid.getAddressDetails(conAddr).paymentCredential.hash
const collateralHash = await lucid.getAddressDetails(cAddr).paymentCredential.hash
const balanceHash = await lucid.validatorToScriptHash(balance)
const liquidateHash = await lucid.validatorToScriptHash(liquidate)
const closeHash = await lucid.validatorToScriptHash(close)

const loanHashz = []
const collateralHashz = [balanceHash, liquidateHash, closeHash]
const mintLoanAction = Data.to(new Constr(0, [loanCurrency, loanAmt, timestamp]))
const burnLoanAction = Data.to(new Constr(1, []))

const configDatum = Data.to(
  new Constr(0, [
    loanHash,
    collateralHash,
    rewardsCS,
    oracleHash,
    loanHashz,
    collateralHashz,
  ])
)

const configUpdateAction = Data.to(
  new Constr(0, [
    loanHash, 
    collateralHash, 
    rewardsCS, 
    oracleHash, 
    loanHashz, 
    collateralHashz
  ])
)

const configCloseAction = Data.to(new Constr(1, []))

const loanDatum = Data.to(
  new Constr(0, [
    loanAmt, 
    interest, 
    rewards, 
    term, 
    timestamp
  ]))
  
const loanBalanceAction = Data.to(new Constr(0, [0]))
const loanLiquidateAction = Data.to(new Constr(0, [1]))
const loanCloseAction = Data.to(new Constr(0, [2]))

const collateralDatum = Data.to(
  new Constr(0, [
    collateralAmt,
    timestamp
  ])
)

const rewardsMintAction = Data.to(new Constr(0, []))
const rewardsBurnAction = Data.to(new Constr(1, []))

const oracleDatum1 = Data.to(new Constr(0, [BigInt(price1), timestamp, interest, fee]))
const oracleDatum2 = Data.to(new Constr(0, [BigInt(price2), timestamp, interest, fee]))
const oracleDatum3 = Data.to(new Constr(0, [BigInt(price3), timestamp, interest, fee]))
const oracleDatum4 = Data.to(new Constr(0, [BigInt(price4), timestamp, interest, fee]))
const oracleDatum5 = Data.to(new Constr(0, [BigInt(price5), timestamp, interest, fee]))
const oracleDatum6 = Data.to(new Constr(0, [BigInt(price6), timestamp, interest, fee]))

const oracleUpdateAction = Data.to(
  new Constr(0, [
    BigInt(price1),
    timestamp,
    interest,
    fee,
  ]))

const oracleCloseAction = Data.to(new Constr(1, []))

const oracleMintAction = Data.to(new Constr(0, []))
const oracleBurnAction = Data.to(new Constr(1, []))
  
    
// ---------------------------------------- //
    
// Transactions //

// ---------------------------------------- //

// Config Transactions //

// The Config Token/Validator Pair holds all of the relevant validator Hashes for the dapp

async function mintConfig() {
  const utxos: [UTxO] = await lucid.getUtxos()
  const utxo: UTxO = utxos[0]
  const index = toHex(utxo.outputIndex)
  const configTN = fromHex(utxo.txHash.concat(index))

  const tx = await Lucid
    .newTx()
    .collectFrom([utxo])
    .mintAssets({
      [toUnit(configCS, configTN)]: 1,
    }, configUpdateAction)
    .attachMintingPolicy(configMint)
    .payToContract(
      configAddr, 
      { inline: configDatum }, 
      { configCS: 1 }
    )
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}

async function burnConfig() {
  const utxos: [UTxO] = await lucid.getUtxosAtWithUnit(configAddr, configCS)
  const utxo: UTxO = utxos[0]

  const tx = await Lucid
    .newTx()
    .collectFrom([utxo], configCloseAction)
    .mintAssets({
      [configCS]: -1,
    }, configCloseAction)
    .attachMintingPolicy(configMint)
    .attachSpendingValidator(configVal)
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}

// The oracle needs to work like a one-shot minting policy where it takes
// The spending utxo to create the token name
// This ensures that even if someone manages to bypass the signature they could
// never duplicate the token
// When testing these transactions you will need to record the token name when you mint,
// and use it as a constant in the subsequent transactions

// Oracle Minting Transactions //

// async function makeOracle() {
//   const utxos: [UTxO] = await lucid.getUtxos()
//   const utxo: UTxO = utxos[0]
  
//   return utxo.txHash.toString() + utxo.outputIndex.toString()
// }

// const oracleTN = await makeOracle()

const oracleTN = fromText("oracleTN") // add TN here after minted oracle
const oracleUnit = "" // input after Mint 

async function mintOracle() {
  const utxos: UTxO[] = await lucid.utxosAt()
  const utxo: UTxO = utxos[0]
  const oracleTN = fromHex(utxo.txHash.concat(toHex(utxo.outputIndex)))
  console.log("Oracle Token Name: ", oracleTN)
  const oracleUnit = toUnit(oracleCS, oracleTN)
  console.log("Oracle Unit: ", oracleUnit)
  
  const tx = await Lucid
    .newTx()
    .collectFrom([utxo])
    .mintAssets({
      [oracleUnit]: 1,
    }, oracleMintAction)
    .attachMintingPolicy(oracleMint)
    .payToContract(
      oracleAddr, 
      { inline: oracleDatum1 }, 
      { [oracleUnit]: 1 }
    )
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.signTx().complete()

  return txSigned.submit()
}

// Oracle Update Functions //

async function oAutoUpdate() {
  const utxos: UTxO[] = await lucid.utxosAtWithUnit(oracleAddr, oracleUnit)
  const utxo: UTxO = utxos[0]

  const tx = await Lucid
    .newTx()
    .collectFrom([utxo], oracleUpdateAction)
    .payToContract(
      oracleAddr, 
      { inline: oracleDatum2 }, 
      { [toUnit(oracleCS, oracleTN)]: 1 }
    )
    .attachSpendingValidator(oracleVal)
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await lucid.signTx().complete()

  return txSigned.submit()

}

async function oManualUpdate() {
  const utxos: [UTxO] = await lucid.getUtxosAtWithUnit(oracleAddr, oracleUnit)
  const utxo: UTxO = utxos[0]

  const tx = await Lucid
    .newTx()
    .collectFrom([utxo], oracleUpdateAction)
    .payToContract(
      oracleAddr, 
      { inline: oracleDatum3 }, 
      { [toUnit(oracleCS, oracleTN)]: 1 }
    )
    .attachSpendingValidator(oracleVal)
    .addSignerKey(userPKH)
    .complete()

  const txSigned = await lucid.signTx().complete()

  return txSigned.submit()
}

async function oracleClose() {
  const utxos: [UTxO] = await lucid.getUtxosAtWithUnit(oracleAddr, oracleUnit)
  const utxo: UTxO = utxos[0]

  const tx = await Lucid
    .newTx()
    .collectFrom([utxo], oracleCloseAction)
    .mintAssets({
      [oracleUnit]: -1,
    }, oracleBurnAction)
    .attachMintingPolicy(oracleMint)
    .attachSpendingValidator(oracleVal)
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await lucid.signTx().complete()

  return txSigned.submit()
}

// Loan Minting Policy Transactions // 

// MintLoan also acts as a one-shot minting policy to keep the policyId the same whilst
// providing a unique token identifier
// this will enable users to have multiple loans and not require their pkh 
// or other as token names

// async function makeLoan() {
//   const utxos: [UTxO] = await lucid.getUtxos()
//   const utxo: UTxO = utxos[0]
//   const loanTN = fromText(utxo.txHash.toString() + utxo.outputIndex.toString())
  
//   return loanTN
// }

// const loanTN = await makeLoan()
const loanTN = fromText("loanTN")
const loanUnit = toUnit(loanCS, loanTN)

async function mintLoan() {
  const utxos: [UTxO] = await lucid.getUtxos()
  const utxo: UTxO = utxos[0]
  const loanTn = fromHex(utxo.txHash.concat(toHex(utxo.outputIndex)))
  const oracleUtxos: UTxO = await lucid.getUtxosAtWithUnit(oracleAddr, oracleUnit)
  const oracleUtxo: UTxO = oracleUtxos[0]
  const oracleDatum = Data.from(oracleUtxo.datum)
  const deposit = oracleDatum[0] * loanAmt * 1000000n
  
  const tx = await Lucid
    .newTx()
    .collectFrom([utxo])
    .collectFrom(oracleUtxo)
    .mintAssets({
      [toUnit(loanTn)]: 2,
    }, mintLoanAction)
    .attachMintingPolicy(loanMint)
    .payToContract(
      loanAddr, 
      { inline: loanDatum }, 
      { loanTn: 1 }
    )
    .payToContract(
      collateralAddr,
      { inline: collateralDatum },
      { lovelace: deposit }
    )
    .addSignerKey(userPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()

}

async function burnLoan() {
  const utxos: UTxO[] = await lucid.getUtxosAtWithUnit(loanAddr, loanUnit)
  const utxo: UTxO = utxos[0]
  const oracleUtxos: UTxO[] = await lucid.getUtxosAtWithUnit(oracleAddr, oracleUnit)
  const oracleUtxo: UTxO = oracleUtxos[0]
  const oracleDatum = Data.from(oracleUtxo.datum)
  const exchange = oracleDatum[0]
  const inDatum = Data.from(utxo.datum)

  const tx = await Lucid
    .newTx()
    .collectFrom([utxo], loanCloseAction)
    .readFrom(oracleUtxo)
    .mintAssets({
      [loanUnit]: -1,
    }, burnLoanAction)
    .attachMintingPolicy(loanMint)
    .addSignerKey(userPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()

}

// Loan Validator Transactions //

async function balanceLoan() {
  const utxos: [UTxO] = await lucid.getUtxosAtWithUnit(loanAddr, loanUnit)
  const utxo: UTxO = utxos[0]
  const inDatum = Data.from(utxo.datum)
  const oracleUtxos: UTxO = await lucid.getUtxosAtWithUnit(oracleAddr, oracleUnit)
  const oracleUtxo: UTxO = oracleUtxos[0]
  const oracleDatum = Data.from(oracleUtxo.datum)
  const oracleExchangeRate = oracleDatum[0]

  const collateralValue = (inDatum.loanAmt * oracleExchangeRate) * 1000000
  const balanceValue = loanAmt

  const balanceDatum = Data.to(
    new Constr(0, [
        inDatum.collateral, 
        collateralValue, 
        inDatum.loanCurrency, 
        inDatum.loanValue, 
        timestamp
      ]))

  const tx = await Lucid
    .newTx()
    .collectFrom([utxo], loanBalanceAction)
    .readFrom(oracleUtxo)
    .payToContract(
      loanAddr, 
      { inline: loanDatum }, 
      { loanTn: 1 }
    )
    .payToContract(
      collateralAddr,
      { inline: collateralDatum },
      { lovelace: deposit }
    )
    .attachSpendingValidator(loanVal)
    .addSignerKey(userPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}

async function liquidateLoan() {
  const utxos: [UTxO] = await lucid.getUtxosAtWithUnit(loanAddr, loanUnit)
  const utxo: UTxO = utxos[0]
  const inDatum = Data.from(utxo.datum)
  const oracleUtxos: UTxO = await lucid.getUtxosAtWithUnit(oracleAddr, oracleUnit)
  const oracleUtxo: UTxO = oracleUtxos[0]
  const oracleDatum = Data.from(oracleUtxo.datum)
  const exchange = oracleDatum[0]
  const collateralValue = inDatum.loanValue * exchange
  const liquidateValue = collateralValue * 1000000

  const liquidateDatum = Data.to(
    new Constr(0, [
        inDatum.collateral, 
        0, 
        inDatum.loanCurrency, 
        0, 
        timestamp
      ]))

  const tx = await Lucid
    .newTx()
    .collectFrom([utxo], loanLiquidateAction)
    .readFrom(oracleUtxo)
    .payToContract(
      loanAddr, 
      { inline: loanDatum }, 
      { loanTn: 1 }
    )
    .payToContract(
      collateralAddr,
      { inline: collateralDatum },
      { lovelace: deposit }
    )
    .attachSpendingValidator(loanVal)
    .addSignerKey(userPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}

async function repayLoan() {
  const utxos: [UTxO] = await lucid.getUtxosAtWithUnit(loanAddr, loanUnit)
  const utxo: UTxO = utxos[0]
  const inDatum = Data.from(utxo.datum)
  const oracleUtxos: UTxO = await lucid.getUtxosAtWithUnit(oracleAddr, oracleUnit)
  const oracleUtxo: UTxO = oracleUtxos[0]
  const oracleDatum = Data.from(oracleUtxo.datum)
  const exchange = oracleDatum[0]
  const collateralValue = inDatum.loanValue * exchange
  const remainingValue = 0

  const repayDatum = Data.to(
    new Constr(0, [
        inDatum.collateral, 
        collateralValue, 
        inDatum.loanCurrency, 
        remainingValue, 
        timestamp
      ]))

  const tx = await Lucid
    .newTx()
    .collectFrom([utxo], loanBalanceAction)
    .readFrom(oracleUtxo)
    .payToContract(
      loanAddr, 
      { inline: loanDatum }, 
      { loanTn: 1 }
    )
    .payToContract(
      collateralAddr,
      { inline: collateralDatum },
      { lovelace: deposit }
    )
    .attachSpendingValidator(loanVal)
    .addSignerKey(userPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}

// Rewards Transactions //

const rewardsUnit = toUnit(rewardsCS, fromText(""))

async function mintRewards() {
  const utxos: [UTxO] = await lucid.getUtxos()
  const utxo: UTxO = utxos[0]

  const tx = await Lucid
    .newTx()
    .collectFrom([utxo])
    .mintAssets({
      [rewardsUnit]: 1,
    }, rewardsMintAction)
    .attachMintingPolicy(rewardsMint)
    .payToContract(
      ownerAddress, 
      { inline: configUpdateAction }, 
      { rewardsUnit: 1 }
    )
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}

async function burnRewards() {
  const utxos: [UTxO] = await lucid.getUtxosAtWithUnit(ownerAddress, rewardsUnit)
  const utxo: UTxO = utxos[0]

  const tx = await Lucid
    .newTx()
    .collectFrom([utxo], rewardsBurnAction)
    .mintAssets({
      [rewardsUnit]: -1,
    }, rewardsBurnAction)
    .attachMintingPolicy(rewardsMint)
    .attachSpendingValidator(configVal)
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}

// ---------------------------------------- //

// Transaction Execution //

// ---------------------------------------- //

// mintOracle 
const mintOracleTx = await mintOracle()
console.log("Mint Oracle Tx: ", mintOracleTx,
  "Oracle Token Name: ", oracleTN
)

// mintConfig
const mintConfigTx = await mintConfig()
console.log("Mint Config Tx: ", mintConfigTx,
  "Config Token Name: ", configTN
)

// burnConfig
const burnConfigTx = await burnConfig()
console.log("Burn Config Tx: ", burnConfigTx)

// updateOracle
const updateOracleTX = await oAutoUpdate()
console.log("Update Oracle Tx: ", updateOracleTX,
  "new Oracle Datum: ", oracleDatum2
)

// updateOracleManual
const updateOracleManualTx = await oManualUpdate()
console.log("Update Oracle Manual Tx: ", updateOracleManualTx,
  "new Oracle Datum: ", oracleDatum3
)

// mintLoan
const mintLoanTx = await mintLoan()
console.log("Mint Loan Tx: ", mintLoanTx,
  "Loan Token Name: ", loanTN
)

// balanceLoan
const balanceLoanTx = await balanceLoan()
console.log("Balance Loan Tx: ", balanceLoanTx)

// liquidateLoan
const liquidateLoanTx = await liquidateLoan()
console.log("Liquidate Loan Tx: ", liquidateLoanTx)

// repayLoan
const repayLoanTx = await repayLoan()
console.log("Repay Loan Tx: ", repayLoanTx)

// burnLoan
const burnLoanTx = await burnLoan()
console.log("Burn Loan Tx: ", burnLoanTx)

// closeOracle
const closeOracleTx = await oracleClose()
console.log("Close Oracle Tx: ", closeOracleTx)

// mintRewards
const mintRewardsTx = await mintRewards()
console.log("Mint Rewards Tx: ", mintRewardsTx)

// burnRewards
const burnRewardsTx = await burnRewards()
console.log("Burn Rewards Tx: ", burnRewardsTx)
