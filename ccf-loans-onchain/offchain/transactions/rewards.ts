import { Lucid, fromText, toUnit, UTxO, } from "https://deno.land/x/lucid@0.10.7/mod.ts";
import { lucid } from "../blockfrost.ts"
import { ownerAddress, ownerPKH } from "../owner.ts";
import { rewardsMintAction, configUpdateAction, rewardsBurnAction } from "../redeemers.ts";
import { rewardsCS, rewardsMint, configVal } from "../validators.ts";


lucid.selectWalletFromPrivateKey(await Deno.readTextFile("./owner.sk"));
// STringify to fix maestro error

// const toCborHex = (rawPrivateKey: string) => {
//   const decoded = bech32.decode(rawPrivateKey);
//   const words = bech32.fromWords(decoded.words);
//   const hexStr = words
//     .map((word) => word.toString(16).padStart(2, "0"))
//     .join("");
//   return "5820" + hexStr;
// };

// const toSkey = () => {
//   return (
//     JSON.stringify(
//       {
//         type: "PaymentSigningKeyShelley_ed25519",
//         description: "Payment Signing Key",
//         cborHex: toCborHex("582020b08d609d925d9106a49e1bcf68c2e4524c4ef25845828c393ff60ebc26d719"),
//       },
//       null,
//       4
//     ) + "\n"
//   );
// };

// Rewards Transactions //

export const rewardsUnit = toUnit(rewardsCS, fromText(""))

export async function mintRewards() {
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

export async function burnRewards() {
  const utxos: UTxO[] = await lucid.getUtxosAtWithUnit(ownerAddress, rewardsUnit)
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