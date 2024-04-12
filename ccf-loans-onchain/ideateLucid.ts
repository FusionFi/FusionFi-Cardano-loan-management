import {
  Blockfrost,
  C,
  Constr,
  Data,
  Lucid,
  SpendingValidator,
  TxHash,
  fromHex,
  fromText,
  toHex,
  toUnit,
  UTxO,
} from "https://deno.land/x/lucid@0.10.7/mod.ts";
import * as cbor from "https://deno.land/x/cbor@v1.4.1/index.js";

// deno run --allow-net --allow-read --allow-env ideate.ts

const BLOCKFROST = "API_KEY"
 
const lucid = await Lucid.new(
  new Blockfrost(
    "https://cardano-preview.blockfrost.io/api/v0",
    BLOCKFROST,
  ),
  "Preview",
);

// ---------------------------------------- //

lucid.selectWalletFromPrivateKey(await Deno.readTextFile("./owner.sk"));
// lucid.selectWalletFromPrivateKey(await Deno.readTextFile("./beneficiary.sk"));
 
const ownerPKH = lucid.utils.getAddressDetails(await Deno.readTextFile("owner.addr"))
.paymentCredential.hash;

const oMint = await readOracleMint()
const oracleCS = lucid.utils.mintingPolicyToId(oMint)
const oVal = await readOracleValidator()
const lMint = await readLoanMint()
const loanCS = lucid.utils.mintingPolicyToId(mint)
const lVal = await readLoanValidator()

// --- Supporting functions

async function readOracleMint(): Promise<MintingPolicy> {
  const validator = JSON.parse(await Deno.readTextFile("plutus.json")).validators[0]
  return {
    type: "PlutusV2",
    script: applyParamsToScript(
      applyDoubleCborEncoding(validator.compiledCode), [ownerPKH]
    ),
  }
}

async function readOracleValidator(): Promise<SpendingValidator> {
  const validator = JSON.parse(await Deno.readTextFile("plutus.json")).validators[1];
  return {
    type: "PlutusV2",
    script: applyParamsToScript(
      applyDoubleCborEncoding(validator.compiledCode), [ownerPKH, oracleCS]
    ),
  };
}

async function readLoanMint(): Promise<MintingPolicy> {
  const validator = JSON.parse(await Deno.readTextFile("plutus.json")).validators[3];
  return {
    type: "PlutusV2",
    script: applyParamsToScript(
      applyDoubleCborEncoding(validator.compiledCode), [oracleCS]
    ),
  };
}

async function readLoanValidator(): Promise<SpendingValidator> {
  const validator = JSON.parse(await Deno.readTextFile("plutus.json")).validators[2];
  return {
    type: "PlutusV2",
    script: applyParamsToScript(
      applyDoubleCborEncoding(validator.compiledCode), [ownerPKH, loanCS]
    ),
  };
}

const ownerAddress = await Deno.readTextFile("./owner.addr");

const beneficiaryPublicKeyHash =
  lucid.utils.getAddressDetails(await Deno.readTextFile("beneficiary.addr"))
.paymentCredential.hash;

const beneficiaryAddress = await Deno.readTextFile("./beneficiary.addr");

// ---------------------------------------- //

const price1 = 0.5
const price2 = 0.55
const price3 = 0.6
const price4 = 0.45
const price5 = 0.4

const mintOracleAction = Data.to(new Constr(0, []))
const updateOracleAction = Data.to(new Constr(0, []))
const burnOracleAction = Data.to(new Constr(1, []))
const mintLoanAction = Data.to(new Constr(0, []))
const burnLoanAction = Data.to(new Constr(1, []))
const balanceLoanAction = Data.to(new Constr(0, []))
const liquidateLoanAction = Data.to(new Constr(1, []))
const closeLoanAction = Data.to(new Constr(2, []))

const oAddr = lucid.utils.validatorToAddress(oVal)
const lAddr = lucid.utils.validatorToAddress(lVal)

const oracleDatum = Data.to(new Constr(0, [BigInt(price1)]))
const loanDatum = Data.to(new Constr(0, [BigInt(price1)]))

// The oracle works like a one-shot minting policy where it takes
// The spending utxo to create the token name
// This ensures that even if someone manages to bypass the signature they could
// never duplicate the token

async function makeOracle() {
  const utxos: [UTxO] = await lucid.getUtxos()
  const utxo: UTxO = utxos[0]
  const oracleTN = fromText(utxo.txHash.toString() + utxo.outputIndex.toString())
  
  return oracleTN
}

const oracleTN = await makeOracle()

async function mintOracle() {
  const utxos: [UTxO] = await lucid.getUtxos()
  const utxo: UTxO = utxos[0]

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
      { [toUnit(oracleCS, oracleTN)]: 1 }
    )
    .addSignerKey(ownerPkh)
    .complete()

  const txSigned = await lucid.signTx().complete()

  return txSigned.submit()
}

const oracleToken = toUnit(oracleCS, oracleTN)

// Oracle Update Functions //

async function oAutoUpdate() {
  const utxos: [UTxO] = await lucid.getUtxosAtWithUnit(oAddr, oracleToken)
  const utxo: UTxO = utxos[0]

  const tx = await Lucid
    .newTx()
    .collectFrom([utxo], updateOracleAction)
    .payToContract(
      oAddr, 
      { inline: oracleDatum }, 
      { [toUnit(oracleCS, oracleTN)]: 1 }
    )
    .attachSpendingValidator(oVal)
    .addSignerKey(ownerPkh)
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
      { inline: oracleDatum }, 
      { [toUnit(oracleCS, oracleTN)]: 1 }
    )
    .attachSpendingValidator(oVal)
    .addSignerKey(userPkh)
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
    .addSignerKey(ownerPkh)
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
  const loanTN = fromText(utxo.txHash.toString() + utxo.outputIndex.toString())
  const oracleUtxos: UTxO = await lucid.getUtxosAtWithUnit(oAddr, oracleToken)
  const oracleUtxo: UTxO = oracleUtxos[0]
  const oracleDatum = Data.from(oracleUtxo.datum)
  
  const tx = await Lucid
    .newTx()
    .collectFrom([utxo])
    .readFrom(oracleUtxo)
    .mintAssets({
      [loanToken]: 1,
    }, mintLoanAction)
    .attachMintingPolicy(lMint)
    .payToContract(
      lAddr, 
      { inline: loanDatum }, 
      { [loanToken]: 1 }
    )
    .addSignerKey(userPkh)
    .complete()

  const txSigned = await lucid.signTx().complete()

  return txSigned.submit()

}

async function burnLoan() {
  const utxos: [UTxO] = await lucid.getUtxosAtWithUnit(lAddr, loanToken)
  const utxo: UTxO = utxos[0]
  const oracleUtxos: UTxO = await lucid.getUtxosAtWithUnit(oAddr, oracleToken)
  const oracleUtxo: UTxO = oracleUtxos[0]
  const oracleDatum = Data.from(oracleUtxo.datum)

  const tx = await Lucid
    .newTx()
    .collectFrom([utxo], lCloseRedeemer)
    .readFrom(oracleUtxo)
    .mintAssets({
      [loanToken]: -1,
    }, burnAction)
    .attachMintingPolicy(lMint)
    .addSignerKey(userPkh)
    .complete()

  const txSigned = await lucid.signTx().complete()

  return txSigned.submit()

}

// Loan Validator Transactions //

async function balanceLoan() {
  const utxos: [UTxO] = await lucid.getUtxosAtWithUnit(lAddr, loanToken)
  const utxo: UTxO = utxos[0]
  const oracleUtxos: UTxO = await lucid.getUtxosAtWithUnit(oAddr, oracleToken)
  const oracleUtxo: UTxO = oracleUtxos[0]
  const oracleDatum = Data.from(oracleUtxo.datum)

  const loanValue = (datum.loanValue * oracleExchangeRate) * 1000000
  const balanceValue = BigInt(loanValue)

  const tx = await Lucid
    .newTx()
    .collectFrom([utxo], balanceLoanAction)
    .readFrom(oracleUtxo)
    .payToContract(
      lAddr, 
      { inline: balanceDatum }, 
      { lovelace: balanceValue, [loanToken]: 1 }
    )
    .attachSpendingValidator(lVal)
    .addSignerKey(userPkh)
    .complete()

  const txSigned = await lucid.signTx().complete()

  return txSigned.submit()
}

async function liquidateLoan() {
  const utxos: [UTxO] = await lucid.getUtxosAtWithUnit(lAddr, loanToken)
  const utxo: UTxO = utxos[0]
  const oracleUtxos: UTxO = await lucid.getUtxosAtWithUnit(oAddr, oracleToken)
  const oracleUtxo: UTxO = oracleUtxos[0]
  const oracleDatum = Data.from(oracleUtxo.datum)

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
    .addSignerKey(userPkh)
    .complete()

  const txSigned = await lucid.signTx().complete()

  return txSigned.submit()
}

async function repayLoan() {
  const utxos: [UTxO] = await lucid.getUtxosAtWithUnit(lAddr, loanToken)
  const utxo: UTxO = utxos[0]
  const oracleUtxos: UTxO = await lucid.getUtxosAtWithUnit(oAddr, oracleToken)
  const oracleUtxo: UTxO = oracleUtxos[0]
  const oracleDatum = Data.from(oracleUtxo.datum)

  const tx = await Lucid
    .newTx()
    .collectFrom([utxo], lRepayRedeemer)
    .readFrom(oracleUtxo)
    .payToContract(
      lAddr, 
      { inline: repayDatum }, 
      { loanToken: 1 }
    )
    .attachSpendingValidator(lVal)
    .addSignerKey(userPkh)
    .complete()

  const txSigned = await lucid.signTx().complete()

  return txSigned.submit()
}