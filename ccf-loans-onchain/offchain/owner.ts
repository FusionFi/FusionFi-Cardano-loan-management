import { lucid } from "./blockfrost.ts"

export const ownerPKH = lucid.utils.getAddressDetails(await Deno.readTextFile("owner.addr"))
.paymentCredential.hash;

export const ownerAddress = await Deno.readTextFile("./owner.addr");