import { lucid } from "./blockfrost.ts"

export const ownerPKH = lucid.utils.getAddressDetails(await Deno.readTextFile("owner.addr"))
  .paymentCredential.hash;

export const ownerAddress = await Deno.readTextFile("./owner.addr");

export const interestPayAddr = "addr_test1vr4m7cd94yhymrwcmgs2k6zs00jql9d075ms0dgxjv2tuxqjy82wz"

export const interestPKH = lucid.utils.getAddressDetails(interestPayAddr)
  .paymentCredential.hash;