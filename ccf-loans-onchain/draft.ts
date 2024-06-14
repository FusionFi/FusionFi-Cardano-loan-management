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
  fromUnit,
  toHex,
  toUnit,
  UTxO,
  utxosAtWithUnit,
  utxosAt,
  WithdrawalValidator,
} from "https://deno.land/x/lucid@0.10.7/mod.ts";
import * as cbor from "https://deno.land/x/cbor@v1.4.1/index.js";
import { load } from "https://deno.land/std@0.224.0/dotenv/mod.ts";

// deno run --allow-net --allow-read --allow-env draft.ts

// TODO: This transaction code is WIP not complete

const env = await load();

const BLOCKFROST = env["BLOCKFROST_API"]
 
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

const configMint = await readConfigMint()
const configCS = lucid.utils.mintingPolicyToId(configMint)
const configVal = await readConfigValidator()
const oracleMint = await readOracleMint()
const oracleCS = lucid.utils.mintingPolicyToId(oracleMint)
const oracleVal = await readOracleValidator()
const loanMint = await readLoanMint()
const loanCS = lucid.utils.mintingPolicyToId(loanMint)
const loanVal = await readLoanValidator()
const collateralVal = await readCollateralValidator()
const rewardsMint = await readRewardsMint()
const rewardsCS = lucid.utils.mintingPolicyToId(rewardsMint)
const balance = await readBalanceValidator()
const liquidate = await readLiquidateValidator()
const close = await readCloseValidator()

// console.log(`OracleCS: `, oracleCS)
// console.log(`
// ConfigCS: 
//   `, configCS, `
//   `)
// console.log(`LoanCS: `, loanCS)
// console.log(`RewardsCS: `, rewardsCS)

const { RewardAddress } = C

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
      applyDoubleCborEncoding(validator.compiledCode), [configCS]
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
      applyDoubleCborEncoding(validator.compiledCode), [ownerPKH, configCS]
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

// const userPKH =
//   lucid.utils.getAddressDetails(await Deno.readTextFile("beneficiary.addr"))
// .paymentCredential.hash;

// const userAddress = await Deno.readTextFile("./beneficiary.addr");

// ---------------------------------------- //

// Transaction Data //

// ---------------------------------------- //

const price1 = 500n
const price2 = 550n
const price3 = 600n
const price4 = 450n
const price5 = 400n
const price6 = 265n

const collateral = fromText("ADA")
const collateralAmt = 10n
const loanCurrency = fromText("USDT")
const loanAmt = 5n
const timestamp = BigInt(new Date().getTime())
const interest = 15n
const fee = 2n
const term = 0n
const rewards = 5n

console.log(`Timestamp:
  `, timestamp, `
`)


const oracleAddr = lucid.utils.validatorToAddress(oracleVal)
const loanAddr = lucid.utils.validatorToAddress(loanVal)
const collateralAddr = lucid.utils.validatorToAddress(collateralVal)
const configAddr = lucid.utils.validatorToAddress(configVal)
const balanceAddr = lucid.utils.validatorToRewardAddress(balance)
const liquidateAddr = lucid.utils.validatorToRewardAddress(liquidate)
const closeAddr = lucid.utils.validatorToRewardAddress(close)

// console.log(`Oracle Address: `, oracleAddr)
// console.log(`Loan Address: `, loanAddr)
// console.log(`Collateral Address: `, collateralAddr)
// console.log(`Config Address: `, configAddr)
// console.log(`Balance Address: `, balanceAddr)
// console.log(`Liquidate Address: `, liquidateAddr)
// console.log(`Close Address: `, closeAddr)
// console.log("")

const oracleHash = await lucid.utils.validatorToScriptHash(oracleVal)
const loanHash = await lucid.utils.validatorToScriptHash(loanVal)
const configHash = await lucid.utils.validatorToScriptHash(configVal)
const collateralHash = await lucid.utils.validatorToScriptHash(collateralVal)
const balanceHash = await lucid.utils.validatorToScriptHash(balance)
const liquidateHash = await lucid.utils.validatorToScriptHash(liquidate)
const closeHash = await lucid.utils.validatorToScriptHash(close)

// console.log(`Oracle Hash: `, oracleHash)
// console.log(`Loan Hash: `, loanHash)
// console.log(`Config Hash: `, collateralHash)
// console.log(`Collateral Hash: `, configHash)
// console.log(`Balance Hash: `, balanceHash)
// console.log(`Liquidate Hash: `, liquidateHash)
// console.log(`Close Hash: `, closeHash)
// console.log("")

const loanHashz = [balanceHash]
const collateralHashz = [balanceHash, liquidateHash, closeHash]
const mintLoanAction = Data.to(new Constr(0, [loanAmt, rewards, term, timestamp]))
const burnLoanAction = Data.to(new Constr(1, []))

// console.log(`Loan Hashes: `, loanHashz)
// console.log(`Collateral Hashes: `, collateralHashz)
// console.log(`Mint Action: `, mintLoanAction)
// console.log(`Burn Action: `, burnLoanAction)
// console.log("")

const configDatum = Data.to(new Constr(0, [
  loanHash,
  collateralHash,
  rewardsCS,
  oracleHash,
  loanHashz,
  collateralHashz,
]))

// console.log(` Config Datum:
//   `, configDatum, `
// `)

const configUpdateAction = Data.to(new Constr(0, [
  loanHash,
  collateralHash,
  rewardsCS,
  oracleHash,
  loanHashz,
  collateralHashz,
]))

// console.log(` Config Update:
//   `, configUpdateAction, `
// `)

const configCloseAction = Data.to(new Constr(1, []))

// console.log(`Config Close: `, configCloseAction)
// console.log("")

const oracleDatum1 = Data.to(new Constr(0, [price1, timestamp, interest, fee, loanCurrency]))
const oracleDatum2 = Data.to(new Constr(0, [price2, timestamp, interest, fee, loanCurrency]))
const oracleDatum3 = Data.to(new Constr(0, [price3, timestamp, interest, fee, loanCurrency]))
const oracleDatum4 = Data.to(new Constr(0, [price4, timestamp, interest, fee, loanCurrency]))
const oracleDatum5 = Data.to(new Constr(0, [price5, timestamp, interest, fee, loanCurrency]))
const oracleDatum6 = Data.to(new Constr(0, [price6, timestamp, interest, fee, loanCurrency]))

// console.log(`Oracle Datum 1: `, oracleDatum1)
// console.log(`Oracle Datum 2: `, oracleDatum2)
// console.log(`Oracle Datum 3: `, oracleDatum1)
// console.log(`Oracle Datum 4: `, oracleDatum2)
// console.log(`Oracle Datum 5: `, oracleDatum1)
// console.log(`Oracle Datum 6: `, oracleDatum2)
// console.log("")

const oracleUpdateAction = Data.to(
  new Constr(0, [
    price1, // change this to match oracleDatum Output or it will fail
    timestamp,
    interest,
    fee,
  ]))

const oracleCloseAction = Data.to(new Constr(1, []))

// console.log(`Oracle Update: `, oracleUpdateAction)
// console.log(`Oracle Close: `, oracleCloseAction)
// console.log("")

const oracleMintAction = Data.to(new Constr(0, []))
const oracleBurnAction = Data.to(new Constr(1, []))

// console.log(`Oracle Mint: `, oracleMintAction)
// console.log(`Oracle Burn: `, oracleBurnAction)
// console.log("")

const oracleUnit = "e75c32da3aad61874dcc7f3a47a8c534fa60eebdccd974f19763f622ea2ccf3a3bb63238e9f4d4e03c82a6"

const oracleTn = fromUnit(oracleUnit).assetName

const loanDatum = Data.to(
  new Constr(0, [
    loanAmt,  
    rewards, 
    term, 
    timestamp, 
    oracleTn
  ]))

// console.log(`Loan Datum: `, loanDatum)
// console.log("")
  
const loanBalanceAction = Data.to(new Constr(0, [0n]))
const loanLiquidateAction = Data.to(new Constr(0, [1n]))
const loanCloseAction = Data.to(new Constr(0, [2n]))

// console.log(`Loan Balance: `, loanBalanceAction)
// console.log(`Loan Liquidate: `, loanLiquidateAction)
// console.log(`Loan CLose: `, loanCloseAction)
// console.log("")

const collateralDatum = Data.to(
  new Constr(0, [
    collateralAmt,
    timestamp
  ])
)

// console.log(`Collateral Datum: `, collateralDatum)
// console.log("")

const rewardsMintAction = Data.to(new Constr(0, []))
const rewardsBurnAction = Data.to(new Constr(1, []))

// console.log(`Rewards Mint Action: `, rewardsMintAction)
// console.log(`Rewards Burn Action: `, rewardsBurnAction)
// console.log("")

    
// ---------------------------------------- //
    
// Transactions //

// ---------------------------------------- //

// Config Transactions //
// console.log(`CONFIGURATION TRANSACTIONS
// `)

// The Config Token/Validator Pair holds all of the relevant validator Hashes for the dapp

const configTN = fromText("") //"227c1b757b4b17515244f1614b402900"
const configUnit = toUnit(configCS, configTN)

// console.log(`Config Unit: 
//   `, configUnit, `
// `)

async function mintConfig() {
  console.log(`CONFIGURATION TRANSACTION
`)
  const utxos: [UTxO] = await lucid.utxosAt(ownerAddress)
  const utxo: UTxO = utxos[0]
  console.log(`User Input UTxO: 
    `, utxo.txHash, `
    `)

  // const index = toHex(utxo.outputIndex.toString())
  // console.log(`Hex Index : 
  //   `, index, `
  //   `)

  // const configTN = utxo.txHash.slice(0, 30).concat(index)
  // console.log(`Config Token Name : 
  //   `, configTN, `
  //   `)

  const tx = await lucid
    .newTx()
    .collectFrom([utxo])
    .mintAssets({
      [configUnit]: 1n,
    }, configUpdateAction)
    .attachMintingPolicy(configMint)
    .payToContract(
      configAddr, 
      { inline: configDatum }, 
      { [configUnit]: 1n }
    )
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}

async function burnConfig() {
  console.log(`CONFIGURATION TRANSACTION
`)
  const utxos: [UTxO] = await lucid.utxosAtWithUnit(configAddr, configUnit)
  const utxo: UTxO = utxos[0]
  console.log(utxo)

  const tx = await lucid
    .newTx()
    .collectFrom([utxo], configCloseAction)
    .mintAssets({
      [configUnit]: -1,
    }, configCloseAction)
    .attachMintingPolicy(configMint)
    .attachSpendingValidator(configVal)
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}

async function updateConfig() {
  console.log(`CONFIGURATION TRANSACTION
`)
  const utxos: [UTxO] = await lucid.utxosAtWithUnit(configAddr, configUnit)
  const utxo: UTxO = utxos[0]
  console.log(`Config Utxo: 
    `, utxo, `
  `)
  console.log(`Config Datum: 
    `,Data.from(configDatum), `
  `)

  const tx = await lucid
    .newTx()
    .collectFrom([utxo], configUpdateAction)
    .attachSpendingValidator(configVal)
    .payToContract(
      configAddr, 
      { inline: configDatum }, 
      { [configUnit]: 1n }
    )
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}

// Oracle Minting Transactions //
// console.log(`ORACLE TRANSACTIONS
// `)

// The oracle needs to work like a one-shot minting policy where it takes
// The spending utxo to create the token name
// This ensures that even if someone manages to bypass the signature they could
// never duplicate the token
// When testing these transactions you will need to record the token name when you mint,
// and use it as a constant in the subsequent transactions

// const oracleTN = fromText("oracleTN") // add TN here after minted oracle
// const oracleUnit = "" // input after Mint 

async function mintOracle() {
  console.log(`ORACLE TRANSACTION
`)
  const utxos: [UTxO] = await lucid.utxosAt(ownerAddress)
  const utxo: UTxO = utxos[0]
  // console.log(utxo)
  const configUtxos: [UTxO] = await lucid.utxosAtWithUnit(configAddr, configUnit)
  const configIn: UTxO = configUtxos[0]
  // console.log(configIn)
  const oracleTN = utxo.txHash.slice(0, 30).concat(toHex(utxo.outputIndex))
  console.log("Oracle Token Name: ", oracleTN)
  const oracleUnit = toUnit(oracleCS, oracleTN)
  console.log("Oracle Unit: ", oracleUnit)
  
  const tx = await lucid
    .newTx()
    .collectFrom([utxo])
    .readFrom([configIn])
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

  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}

// Oracle Update Functions //

async function oAutoUpdate() {
  console.log(`ORACLE TRANSACTION
    `)
  const utxos: UTxO[] = await lucid.utxosAtWithUnit(oracleAddr, oracleUnit)
  const utxo: UTxO = utxos[0]
  console.log(`Oracle Input UTxO: 
  `, utxo, `
  `)

  const tx = await lucid
    .newTx()
    .collectFrom([utxo], oracleUpdateAction)
    .payToContract(
      oracleAddr, 
      { inline: oracleDatum1 }, 
      { [oracleUnit]: 1 }
    )
    .attachSpendingValidator(oracleVal)
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()

}

async function oManualUpdate() {
  console.log(`ORACLE TRANSACTION
    `)
  const utxos: [UTxO] = await lucid.utxosAtWithUnit(oracleAddr, oracleUnit)
  const utxo: UTxO = utxos[0]

  const tx = await lucid
    .newTx()
    .collectFrom([utxo], oracleUpdateAction)
    .payToContract(
      oracleAddr, 
      { inline: oracleDatum3 }, 
      { [oracleUnit]: 1 }
    )
    .attachSpendingValidator(oracleVal)
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}

async function oracleClose() {
  console.log(`ORACLE TRANSACTION
    `)

  const utxos: UTxO[] = await lucid.utxosAtWithUnit(oracleAddr, oracleUnit)
  const utxo: UTxO = utxos[0]
  console.log(utxo)

  const tx = await lucid
    .newTx()
    .collectFrom([utxo], oracleCloseAction)
    .attachSpendingValidator(oracleVal)
    .mintAssets({
      [oracleUnit]: -1,
    }, oracleBurnAction)
    .attachMintingPolicy(oracleMint)
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}

// Loan Minting Policy Transactions // 
// console.log(`Loan Minting Transactions
//   `)

// MintLoan also acts as a one-shot minting policy to keep the policyId the same whilst
// providing a unique token identifier
// this will enable users to have multiple loans and not require their pkh 
// or other as token names

async function mintLoan() {
  console.log(`Loan Minting Transaction
  `)

  const utxos: UTxO[] = await lucid.utxosAt(ownerAddress)
  const utxo: UTxO = utxos[0]
  const loanTn = utxo.txHash.slice(0, 30).concat(toHex(utxo.outputIndex))
  const loanUnit = toUnit(loanCS, loanTn)
  const configUtxos = await lucid.utxosAtWithUnit(configAddr, configUnit)
  const configIn = configUtxos[0]
  const oracleUtxos: UTxO[] = await lucid.utxosAtWithUnit(oracleAddr, oracleUnit)
  const oracleUtxo: UTxO = oracleUtxos[0]
  const oracleOutDatum = Data.from(oracleDatum1) // Change the oracle datum here
  const deposit = loanAmt * 1000n / oracleOutDatum.fields[0]

  console.log(`Loan Token Name: `, loanTn)
  console.log(`Loan Unit: `, loanUnit)
  // console.log(`Loan Amount: `, loanAmt)
  // console.log(`Oracle Price: `, oracleOutDatum.fields[0])
  // console.log(`Deposit`, deposit)
  // console.log(`Loan Datum: `, Data.from(loanDatum))
  // console.log(`Collateral Datum: `, Data.from(collateralDatum))
  console.log(`Collateral Value: `, deposit * 1000000n)
  console.log(`Expected Collateral: `, ((loanAmt * 1000n) / oracleOutDatum.fields[0]) * 1000000n )
  
  const tx = await lucid
    .newTx()
    .collectFrom([utxo])
    .collectFrom([oracleUtxo], oracleUpdateAction)
    .readFrom([configIn])
    .mintAssets({
      [loanUnit]: 2,
    }, mintLoanAction)
    .attachMintingPolicy(loanMint)
    .payToContract(
      loanAddr, 
      { inline: loanDatum }, 
      { [loanUnit]: 1 }
    )
    .payToContract(
      collateralAddr,
      { inline: collateralDatum },
      { lovelace: (deposit * 1000000n), [loanUnit]: 1 }
    )
    .payToContract(
      oracleAddr,
      { inline: Data.to(oracleOutDatum) },
      { [oracleUnit]: 1 }
    )
    .attachSpendingValidator(oracleVal)
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}

const loanUnit = "bcb4b7cc49cdfa05d6964c79e62b1bb4df59172c7010f4e55b1f13cfdddbc457de675964a37f0fc52dd3b0"

// const loanTN = fromText("loanTN")
// const loanUnit = toUnit(loanCS, loanTN)

async function burnLoan() {
  console.log(`BURN LOAN TRANSACTION
    `)
  const lUtxos: UTxO[] = await lucid.utxosAtWithUnit(loanAddr, loanUnit)
  const lUtxo: UTxO = lUtxos[0]
  console.log(`Loan Utxo: `, lUtxo, `
    `)
  const cUtxos: UTxO[] = await lucid.utxosAtWithUnit(collateralAddr, loanUnit)
  const cUtxo: UTxO = cUtxos[0]
  console.log(`Collateral Utxo: `, cUtxo, `
    `)
  const configUtxos = await lucid.utxosAtWithUnit(configAddr, configUnit)
  const configIn = configUtxos[0]
  const oracleUtxos: UTxO[] = await lucid.utxosAtWithUnit(oracleAddr, oracleUnit)
  const oracleUtxo: UTxO = oracleUtxos[0]
  const oracleDatum = Data.from(oracleUtxo.datum)
  const exchange = oracleDatum[0]
  const inDatum = Data.from(lUtxo.datum)

  const withdrawRedeemer = Data.to(
    new Constr(0, [
      [1n]
    ])
  )

  console.log(`ConfigDatum: `, Data.from(configIn.datum), `
    `)
  
  console.log(`Close Hash: `, closeHash, `
    `)

  const tx = await lucid
    .newTx()
    .collectFrom([lUtxo], loanCloseAction)
    .collectFrom([cUtxo], loanCloseAction)
    .readFrom([configIn])
    .collectFrom([oracleUtxo], oracleUpdateAction)
    .mintAssets({
      [loanUnit]: -2,
    }, burnLoanAction)
    .attachMintingPolicy(loanMint)
    .payToContract(oracleAddr, 
      { inline: oracleDatum1 }, 
      { [oracleUnit]: 1 } 
    )
    .withdraw(closeAddr, 0n, withdrawRedeemer)
    .attachSpendingValidator(loanVal)
    .attachSpendingValidator(collateralVal)
    .attachSpendingValidator(oracleVal)
    .attachWithdrawalValidator(close)
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()

}

// // Loan Validator Transactions //

async function balanceLoan() {
  console.log(`BALANCE LOAN TRANSACTION
    `)
  const lUtxos: UTxO[] = await lucid.utxosAtWithUnit(loanAddr, loanUnit)
  const lUtxo: UTxO = lUtxos[0]
  console.log(lUtxo)
  const cUtxos: UTxO[] = await lucid.utxosAtWithUnit(collateralAddr, loanUnit)
  const cUtxo: UTxO = cUtxos[0]
  console.log(cUtxo)
  const inDatum = Data.from(lUtxo.datum)
  const configUtxos = await lucid.utxosAtWithUnit(configAddr, configUnit)
  const configIn = configUtxos[0]
  console.log(configIn)
  const oracleUtxos: UTxO[] = await lucid.utxosAtWithUnit(oracleAddr, oracleUnit)
  const oracleUtxo: UTxO = oracleUtxos[0]
  console.log(oracleUtxo)
  const oracleDatum = Data.from(oracleDatum1)
  const oracleExchangeRate = oracleDatum.fields[0]
  const adaValue = loanAmt * 1000n / oracleExchangeRate
  const deposit = adaValue * 1000000n
  // console.log(redeemerList)
  const withdrawRedeemer = Data.to(
    new Constr(0, [
      [0n]
    ])
  )

  console.log(`WithdrawRedeemer Redeemer: `, Data.from(withdrawRedeemer))

  const tx = await lucid
    .newTx()
    .collectFrom([lUtxo], loanBalanceAction)
    .collectFrom([cUtxo], loanBalanceAction)
    .collectFrom([oracleUtxo], oracleUpdateAction)
    .readFrom([configIn])
    .withdraw(balanceAddr, 0n, withdrawRedeemer)
    .payToContract(
      loanAddr, 
      { inline: loanDatum }, 
      { [loanUnit]: 1 }
    )
    .payToContract(
      collateralAddr,
      { inline: collateralDatum },
      { lovelace: deposit,
        [loanUnit]: 1,
      }
    )
    .payToContract(
      oracleAddr,
      { inline: oracleDatum1 },
      { [oracleUnit]: 1 }
    )
    .attachSpendingValidator(loanVal)
    .attachSpendingValidator(collateralVal)
    .attachSpendingValidator(oracleVal)
    .attachWithdrawalValidator(balance)
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}

async function liquidateLoan() {
  console.log(`LIQUIDATE LOAN TRANSACTION
    `)
  const newLoanValue = 0n
  const lUtxos: UTxO[] = await lucid.utxosAtWithUnit(loanAddr, loanUnit)
  const lUtxo: UTxO = lUtxos[0]
  console.log(lUtxo)
  const inDatum = Data.from(lUtxo.datum)
  const cUtxos: UTxO[] = await lucid.utxosAtWithUnit(collateralAddr, loanUnit)
  const cUtxo: UTxO = cUtxos[0]
  console.log(cUtxo)
  const configUtxos = await lucid.utxosAtWithUnit(configAddr, configUnit)
  const configIn = configUtxos[0]
  console.log(configIn)
  const oracleUtxos: UTxO[] = await lucid.utxosAtWithUnit(oracleAddr, oracleUnit)
  const oracleUtxo: UTxO = oracleUtxos[0]
  console.log(oracleUtxo)
  const withdrawRedeemer = Data.to(
    new Constr(0, [
      [0n]
    ])
  )

  const liquidateDatum = Data.to(
    new Constr(0, [
        newLoanValue, 
        newLoanValue, 
        0n, 
        timestamp,
        oracleTn
      ]))

  const liquidCollateralDatum = Data.to(
    new Constr(0, [
      newLoanValue * 2n,
      timestamp
    ])
  )

  const tx = await lucid
    .newTx()
    .collectFrom([lUtxo], loanLiquidateAction)
    .collectFrom([cUtxo], loanLiquidateAction)
    .collectFrom([oracleUtxo], oracleUpdateAction)
    .readFrom([configIn])
    .payToContract(
      loanAddr, 
      { inline: liquidateDatum }, 
      { [loanUnit]: 1 }
    )
    .payToContract(
      collateralAddr,
      { inline: liquidCollateralDatum },
      { lovelace: 2000000n, [loanUnit]: 1 }
    )
    .payToContract(
      oracleAddr,
      { inline: oracleDatum1 },
      { [oracleUnit]: 1}
    )
    .attachSpendingValidator(oracleVal)
    .attachSpendingValidator(loanVal)
    .attachSpendingValidator(collateralVal)
    .withdraw(liquidateAddr, 0n, withdrawRedeemer)
    .attachWithdrawalValidator(liquidate)
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}

async function repayLoan() {
  const lUtxos: UTxO[] = await lucid.utxosAtWithUnit(loanAddr, loanUnit)
  console.log(loanAddr)
  const lUtxo: UTxO = lUtxos[0]
  const inDatum = Data.from(lUtxo.datum)
  const cUtxos: UTxO[] = await lucid.utxosAtWithUnit(collateralAddr, loanUnit)
  const cUtxo: UTxO = cUtxos[0]
  const configUtxos = await lucid.utxosAtWithUnit(configAddr, configUnit)
  const configIn = configUtxos[0]
  const oracleUtxos: UTxO[] = await lucid.utxosAtWithUnit(oracleAddr, oracleUnit)
  const oracleUtxo: UTxO = oracleUtxos[0]
  const oracleDatum = Data.from(oracleUtxo.datum)
  const exchange = oracleDatum.fields[0]
  const collateralValue = 2000000n
  const remainingValue = 0n
  const loanOutIndex = 0n
  const collateralOutIndex = 4n
  // const redeemer = Data.Array(Data.Map(loanOutIndex, collateralOutIndex))
  
  console.log()
  
  const withdrawRedeemer = Data.to(
    new Constr(0, [
      [0n]
    ])
  )

  // const repayDatum = Data.to(
  //   new Constr(0, [
  //       inDatum.collateral, 
  //       collateralValue, 
  //       inDatum.loanCurrency, 
  //       remainingValue, 
  //       timestamp
  //     ]))

  const loanDatum = Data.to(
    new Constr(0, [
      remainingValue,  
      rewards, 
      term, 
      timestamp, 
      oracleTn
    ])
  )

  const collateralDatum = Data.to(
    new Constr(0, [
      remainingValue,
      timestamp
    ])
  )

  console.log(`Loan In UTxO: `, lUtxo, `
    `)
  console.log(`Collateral In UTxO: `, cUtxo, `
    `)
  console.log(`Loan Redeemer: `, withdrawRedeemer)

  const tx = await lucid
    .newTx()
    .collectFrom([lUtxo], loanBalanceAction)
    .collectFrom([cUtxo], loanBalanceAction)
    .collectFrom([oracleUtxo], oracleUpdateAction)
    .readFrom([configIn])
    .payToContract(
      loanAddr, 
      { inline: loanDatum }, 
      { [loanUnit]: 1 }
    )
    .payToContract(
      collateralAddr,
      { inline: collateralDatum },
      { lovelace: collateralValue, [loanUnit]: 1 }
    )
    .payToContract(
      oracleAddr,
      { inline: oracleDatum1 },
      { [oracleUnit]: 1 }
    )
    .withdraw(balanceAddr, 0, withdrawRedeemer)
    .attachSpendingValidator(loanVal)
    .attachSpendingValidator(collateralVal)
    .attachSpendingValidator(oracleVal)
    .attachWithdrawalValidator(balance)
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}

// // Rewards Transactions //

// const rewardsUnit = toUnit(rewardsCS, fromText(""))

// async function mintRewards() {
//   const utxos: [UTxO] = await lucid.getUtxos()
//   const utxo: UTxO = utxos[0]

//   const tx = await Lucid
//     .newTx()
//     .collectFrom([utxo])
//     .mintAssets({
//       [rewardsUnit]: 1,
//     }, rewardsMintAction)
//     .attachMintingPolicy(rewardsMint)
//     .payToContract(
//       ownerAddress, 
//       { inline: configUpdateAction }, 
//       { rewardsUnit: 1 }
//     )
//     .addSignerKey(ownerPKH)
//     .complete()

//   const txSigned = await tx.sign().complete()

//   return txSigned.submit()
// }

// async function burnRewards() {
//   const utxos: UTxO[] = await lucid.getUtxosAtWithUnit(ownerAddress, rewardsUnit)
//   const utxo: UTxO = utxos[0]

//   const tx = await Lucid
//     .newTx()
//     .collectFrom([utxo], rewardsBurnAction)
//     .mintAssets({
//       [rewardsUnit]: -1,
//     }, rewardsBurnAction)
//     .attachMintingPolicy(rewardsMint)
//     .attachSpendingValidator(configVal)
//     .addSignerKey(ownerPKH)
//     .complete()

//   const txSigned = await tx.sign().complete()

//   return txSigned.submit()
// }

async function registerStake() {
  const tx = await lucid
    .newTx()
    .registerStake(closeAddr)
    .complete()
  
  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}

async function splitUtxos() {
  const tx = await lucid
    .newTx()
    .payToAddress(ownerAddress, {lovelace: 100000000n})
    .payToAddress(ownerAddress, {lovelace: 100000000n})
    .payToAddress(ownerAddress, {lovelace: 100000000n})
    .payToAddress(ownerAddress, {lovelace: 100000000n})
    .payToAddress(ownerAddress, {lovelace: 100000000n})
    .complete()

  const signedTx = await tx.sign().complete()

  return signedTx.submit()
}

// ---------------------------------------- //

// Transaction Execution //

// ---------------------------------------- //

// // Make Wallet UTxOs
// const splitUtxosTx = await splitUtxos()
// console.log(`Split Tx: 
//   `, splitUtxosTx, `
// `)

// mintConfig
const mintConfigTx = await mintConfig()
console.log(`Mint Config Tx: 
  `, mintConfigTx, `

NEXT RUN THE ORACLE MINTING TRANSACTION
`)

// // burnConfig
// const burnConfigTx = await burnConfig()
// console.log("Burn Config Tx: ", burnConfigTx)

// // updateConfig
// const updateConfigTx = await updateConfig()
// console.log(`Update Config Tx: `, updateConfigTx, `
// `)

// // mintOracle 
// const mintOracleTx = await mintOracle()
// console.log(`Mint Oracle Tx: 
//  `, mintOracleTx, `

// SAVE THE ORACLE UNIT AT LINE 338
//   Or the other transactions will not work!
// `)

// // closeOracle
// const closeOracleTx = await oracleClose()
// console.log(`Burned Oracle Tx: `, closeOracleTx, `
// `)

// // updateOracle
// const updateOracleTX = await oAutoUpdate()
// console.log("Update Oracle Tx: ", updateOracleTX,`
//   new Oracle Datum: `, oracleDatum2, `
//   `
// )

// // updateOracleManual
// const updateOracleManualTx = await oManualUpdate()
// console.log(`Update Oracle Manual Tx: 
//   `, updateOracleManualTx, `

// New Oracle Datum: 
//   `, oracleDatum3
// )

// // mintLoan
// const mintLoanTx = await mintLoan()
// console.log(`Mint Loan Tx: 
//   `, mintLoanTx, `

// Loan Datum: 
//   Amt: `, loanAmt, `
//   Rewards: `, rewards, `
//   Term: `, term, `
//   Timestamp: `, timestamp, `
//   Oracle: `, oracleTn, `

// // NOW YOU CAN BALANCE, LIQUIDATE AND CLOSE THE LOAN

// `)

// // register stake address -> Done
// const registerAddTx = await registerStake()
// console.log("Register Stake Address: ", registerAddTx)

// // balanceLoan -> Done
// const balanceLoanTx = await balanceLoan()
// console.log("Balance Loan Tx: ", balanceLoanTx)

// // liquidateLoan -> Done
// const liquidateLoanTx = await liquidateLoan()
// console.log("Liquidate Loan Tx: ", liquidateLoanTx)

// // repayLoan -> Done
// const repayLoanTx = await repayLoan()
// console.log("Repay Loan Tx: ", repayLoanTx)

// // burnLoan
// const burnLoanTx = await burnLoan()
// console.log("Burn Loan Tx: ", burnLoanTx)

// // closeOracle
// const closeOracleTx = await oracleClose()
// console.log("Close Oracle Tx: ", closeOracleTx)

// // mintRewards
// const mintRewardsTx = await mintRewards()
// console.log("Mint Rewards Tx: ", mintRewardsTx)

// // burnRewards
// const burnRewardsTx = await burnRewards()
// console.log("Burn Rewards Tx: ", burnRewardsTx)
