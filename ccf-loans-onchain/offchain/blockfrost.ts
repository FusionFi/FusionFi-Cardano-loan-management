import { Blockfrost, Lucid, } from "https://deno.land/x/lucid@0.10.7/mod.ts";
import { load } from "https://deno.land/std@0.224.0/dotenv/mod.ts";

const env = await load();

const BLOCKFROST = env["BLOCKFROST_API"]
 
export const lucid = await Lucid.new(
  new Blockfrost(
    "https://cardano-preview.blockfrost.io/api/v0",
    BLOCKFROST,
  ),
  "Preview",
);