import { Blockfrost, Lucid, } from "https://deno.land/x/lucid@0.10.7/mod.ts";
import { load } from "https://deno.land/std@0.224.0/dotenv/mod.ts";

const env = await load();

const BLOCKFROST = env["previewuhHXgLJ4G4pVSzffCS8oNYfG3FegOiZ7"]

export const lucid = await Lucid.new(
  new Blockfrost(
    "https://cardano-preview.blockfrost.io/api/v0",
    "previewuhHXgLJ4G4pVSzffCS8oNYfG3FegOiZ7",
  ),
  "Preview",
);