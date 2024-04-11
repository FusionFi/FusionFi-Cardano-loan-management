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

const price1 = 0.5
const price2 = 0.55
const price3 = 0.6
const price4 = 0.45
const price5 = 0.4

const mintAction = Data.to(new Constr(0, []))

const oracleCS = lucid.utils.mintingPolicyToId(oMint)
const oAddr = lucid.utils.validatorToAddress(oVal)

const oracleDatum = Data.to(new Constr(0, [BigInt(price1)]))

// The oracle works like a one-shot minting policy where it takes
// The spending utxo to create the token name
// This ensures that even if someone manages to bypass the signature they could
// never duplicate the token

async function mintOracle() {
  const utxos: [UTxO] = await lucid.getUtxos()
  const utxo: UTxO = utxos[0]
  const oracleTN = fromText(utxo.txHash.toString() + utxo.outputIndex.toString())

  const tx = await Lucid
    .newTx()
    .mintAssets({
      [toUnit(oracleCS, oracleTN)]: 1,
    }, mintAction)
    .attachMintingPolicy(mintLoan)
    .mustSpend([utxo])
    .payToContract(
      oAddr, 
      { inline: oracleDatum }, 
      { [toUnit(oracleCS, oracleTN)]: 1 }
    )
    .addSignerKey(userPkh)
    .complete()

  const txSigned = await lucid.signTx().complete()

  return txSigned.submit()
}

// Oracle Update Functions //

async function oAutoUpdate() {

}

async function oManualUpdate() {
  
}

async function oracleClose() {

}

// Loan Minting Policy Transactions // 

// MintLoan also acts as a one-shot minting policy to keep the policyId the same whilst
// providing a unique token identifier
// this will enable users to have multiple loans and not require their pkh 
// or other as token names

async function mintLoan() {

}

async function burnLoan() {

}

// Loan Validator Transactions //

async function marginLoan() {

}

async function liquidateLoan() {

}

async function repayLoan() {

}