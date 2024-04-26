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
// lucid.selectWalletFromPrivateKey(await Deno.readTextFile("./beneficiary.sk"));
 
const ownerPKH = lucid.utils.getAddressDetails(await Deno.readTextFile("owner.addr"))
.paymentCredential.hash;

const oMint = await readOracleMint()
const oracleCS = lucid.utils.mintingPolicyToId(oMint)
const oVal = await readOracleValidator()
const configMint = await readConfigMint()
const configCS = lucid.utils.mintingPolicyToId(configMint)
const conVal = await readConfigValidator()
const lMint = await readLoanMint()
const loanCS = lucid.utils.mintingPolicyToId(lMint)
const lVal = await readLoanValidator()
const cVal = await readCollateralValidator()
const rMint = await readRewardsMint()

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

async function readConfigValidator(): Promise<SpendingValidator> {
  const validator = JSON.parse(await Deno.readTextFile("plutus.json")).validators[2];
  return {
    type: "PlutusV2",
    script: applyParamsToScript(
      applyDoubleCborEncoding(validator.compiledCode), [ownerPKH, configCS]
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
      applyDoubleCborEncoding(validator.compiledCode), [oracleCS, loanCS, configCS]
    ),
  };
}

async function readOracleMint(): Promise<MintingPolicy> {
  const validator = JSON.parse(await Deno.readTextFile("plutus.json")).validators[5]
  return {
    type: "PlutusV2",
    script: applyParamsToScript(
      applyDoubleCborEncoding(validator.compiledCode), [ownerPKH]
    ),
  }
}

async function readOracleValidator(): Promise<SpendingValidator> {
  const validator = JSON.parse(await Deno.readTextFile("plutus.json")).validators[6];
  return {
    type: "PlutusV2",
    script: applyParamsToScript(
      applyDoubleCborEncoding(validator.compiledCode), [ownerPKH, oracleCS]
    ),
  };
}

async function readRewardsMint(): Promise<MintingPolicy> {
  const validator = JSON.parse(await Deno.readTextFile("plutus.json")).validators[7];
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

const collateral = "ADA"
const collateralValue = 1000n
const loanCurrency = "USDT"
const loanValue = 500n
const timestamp = new Date().getTime()
const rate = 15n
const fee = 2n

const mintOracleAction = Data.to(new Constr(0, []))
const updateOracleAction = Data.to(new Constr(0, [BigInt(price2), timestamp, rate, fee]))
const burnOracleAction = Data.to(new Constr(1, []))
const mintLoanAction = Data.to(new Constr(0, []))
const burnLoanAction = Data.to(new Constr(1, []))
const balanceLoanAction = Data.to(new Constr(0, []))
const liquidateLoanAction = Data.to(new Constr(1, []))
const closeLoanAction = Data.to(new Constr(2, []))

const oracleDatum = Data.to(new Constr(0, [BigInt(price1), timestamp]))
const loanDatum = Data.to(
    new Constr(0, [
        collateral, 
        collateralValue, 
        loanCurrency, 
        loanValue, 
        timestamp
      ]))

const oracleDatum2 = Data.to(new Constr(0, [BigInt(price2), timestamp]))
const oracleDatum3 = Data.to(new Constr(0, [BigInt(price3), timestamp]))
const oracleDatum4 = Data.to(new Constr(0, [BigInt(price4), timestamp]))
const oracleDatum5 = Data.to(new Constr(0, [BigInt(price5), timestamp]))
const oracleDatum6 = Data.to(new Constr(0, [BigInt(price6), timestamp]))

const oAddr = lucid.utils.validatorToAddress(oVal)
const lAddr = lucid.utils.validatorToAddress(lVal)

// ---------------------------------------- //

// Transactions //

// ---------------------------------------- //

// The oracle works like a one-shot minting policy where it takes
// The spending utxo to create the token name
// This ensures that even if someone manages to bypass the signature they could
// never duplicate the token

// Oracle Minting Transactions //

// async function makeOracle() {
//   const utxos: [UTxO] = await lucid.getUtxos()
//   const utxo: UTxO = utxos[0]
  
//   return utxo.txHash.toString() + utxo.outputIndex.toString()
// }

// const oracleTN = await makeOracle()

const oracleTN = "oracleTN"
const oracleToken = toUnit(oracleCS, oracleTN)

async function mintOracle() {
  const utxos: [UTxO] = await lucid.getUtxos()
  const utxo: UTxO = utxos[0]
  const oracleTN = fromText(utxo.txHash.toString() + utxo.outputIndex.toString())
  console.log("Oracle Token Name: ", oracleTN)
  const oracleUnit = toUnit(oracleCS, oracleTN)
  console.log("Oracle Unit: ", oracleUnit)
  
  const tx = await Lucid
    .newTx()
    .collectFrom([utxo])
    .mintAssets({
      [toUnit(oracleCS, oracleTN)]: 1,
    }, mintOracleAction)
    .attachMintingPolicy(oMint)
    .payToContract(
      oAddr, 
      { inline: oracleDatum }, 
      { [oracleUnit]: 1 }
    )
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await tx.signTx().complete()

  return txSigned.submit()
}

// Oracle Update Functions //

async function oAutoUpdate() {
  const utxos: [UTxO] = await lucid.getUtxosAtWithUnit(oAddr, oracleToken)
  const utxo: UTxO = utxos[0]

  const tx = await Lucid
    .newTx()
    .collectFrom([utxo], updateOracleAction)
    .payToContract(
      oAddr, 
      { inline: oracleDatum2 }, 
      { [toUnit(oracleCS, oracleTN)]: 1 }
    )
    .attachSpendingValidator(oVal)
    .addSignerKey(ownerPKH)
    .complete()

  const txSigned = await lucid.signTx().complete()

  return txSigned.submit()

}

async function oManualUpdate() {
  const utxos: [UTxO] = await lucid.getUtxosAtWithUnit(oAddr, oracleToken)
  const utxo: UTxO = utxos[0]

  const tx = await Lucid
    .newTx()
    .collectFrom([utxo], updateOracleAction)
    .payToContract(
      oAddr, 
      { inline: oracleDatum3 }, 
      { [toUnit(oracleCS, oracleTN)]: 1 }
    )
    .attachSpendingValidator(oVal)
    .addSignerKey(userPKH)
    .complete()

  const txSigned = await lucid.signTx().complete()

  return txSigned.submit()
}

async function oracleClose() {
  const utxos: [UTxO] = await lucid.getUtxosAtWithUnit(oAddr, oracleToken)
  const utxo: UTxO = utxos[0]

  const tx = await Lucid
    .newTx()
    .collectFrom([utxo], burnOracleAction)
    .mintAssets({
      [oracleToken]: -1,
    }, burnOracleAction)
    .attachMintingPolicy(oMint)
    .attachSpendingValidator(oVal)
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

async function makeLoan() {
  const utxos: [UTxO] = await lucid.getUtxos()
  const utxo: UTxO = utxos[0]
  const loanTN = fromText(utxo.txHash.toString() + utxo.outputIndex.toString())
  
  return loanTN
}

const loanTN = await makeLoan()

const loanToken = toUnit(loanCS, loanTN)

async function mintLoan() {
  const utxos: [UTxO] = await lucid.getUtxos()
  const utxo: UTxO = utxos[0]
  const loanTn = fromText(utxo.txHash.toString() + utxo.outputIndex.toString())
  const oracleUtxos: UTxO = await lucid.getUtxosAtWithUnit(oAddr, oracleToken)
  const oracleUtxo: UTxO = oracleUtxos[0]
  const oracleDatum = Data.from(oracleUtxo.datum)
  const deposit = oracleDatum[0] * loanValue * 1000000
  
  const tx = await Lucid
    .newTx()
    .collectFrom([utxo])
    .readFrom(oracleUtxo)
    .mintAssets({
      [loanTn]: 1,
    }, mintLoanAction)
    .attachMintingPolicy(lMint)
    .payToContract(
      lAddr, 
      { inline: loanDatum }, 
      { lovelace: deposit,
        loanTn: 1 
      }
    )
    .addSignerKey(userPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()

}

async function burnLoan() {
  const utxos: [UTxO] = await lucid.getUtxosAtWithUnit(lAddr, loanToken)
  const utxo: UTxO = utxos[0]
  const oracleUtxos: UTxO = await lucid.getUtxosAtWithUnit(oAddr, oracleToken)
  const oracleUtxo: UTxO = oracleUtxos[0]
  const oracleDatum = Data.from(oracleUtxo.datum)
  const exchange = oracleDatum[0]
  const inDatum = Data.from(utxo.datum)

  const tx = await Lucid
    .newTx()
    .collectFrom([utxo], closeLoanAction)
    .readFrom(oracleUtxo)
    .mintAssets({
      [loanToken]: -1,
    }, burnLoanAction)
    .attachMintingPolicy(lMint)
    .addSignerKey(userPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()

}

// Loan Validator Transactions //

async function balanceLoan() {
  const utxos: [UTxO] = await lucid.getUtxosAtWithUnit(lAddr, loanToken)
  const utxo: UTxO = utxos[0]
  const inDatum = Data.from(utxo.datum)
  const oracleUtxos: UTxO = await lucid.getUtxosAtWithUnit(oAddr, oracleToken)
  const oracleUtxo: UTxO = oracleUtxos[0]
  const oracleDatum = Data.from(oracleUtxo.datum)
  const oracleExchangeRate = oracleDatum[0]

  const collateralValue = (inDatum.loanValue * oracleExchangeRate) * 1000000
  const balanceValue = BigInt(loanValue)

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
    .collectFrom([utxo], balanceLoanAction)
    .readFrom(oracleUtxo)
    .payToContract(
      lAddr, 
      { inline: balanceDatum }, 
      { lovelace: balanceValue, loanToken: 1 }
    )
    .attachSpendingValidator(lVal)
    .addSignerKey(userPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}

async function liquidateLoan() {
  const utxos: [UTxO] = await lucid.getUtxosAtWithUnit(lAddr, loanToken)
  const utxo: UTxO = utxos[0]
  const inDatum = Data.from(utxo.datum)
  const oracleUtxos: UTxO = await lucid.getUtxosAtWithUnit(oAddr, oracleToken)
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
    .collectFrom([utxo], liquidateLoanAction)
    .readFrom(oracleUtxo)
    .payToContract(
      lAddr, 
      { inline: liquidateDatum }, 
      { loanToken: 1 }
    )
    .attachSpendingValidator(lVal)
    .addSignerKey(userPKH)
    .complete()

  const txSigned = await tx.sign().complete()

  return txSigned.submit()
}

async function repayLoan() {
  const utxos: [UTxO] = await lucid.getUtxosAtWithUnit(lAddr, loanToken)
  const utxo: UTxO = utxos[0]
  const inDatum = Data.from(utxo.datum)
  const oracleUtxos: UTxO = await lucid.getUtxosAtWithUnit(oAddr, oracleToken)
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
    .collectFrom([utxo], balanceLoanAction)
    .readFrom(oracleUtxo)
    .payToContract(
      lAddr, 
      { inline: repayDatum }, 
      { loanToken: 1 }
    )
    .attachSpendingValidator(lVal)
    .addSignerKey(userPKH)
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
