use aiken/collection/dict
use aiken/collection/list
use cardano/address.{Script}
use cardano/assets.{PolicyId}
use cardano/transaction.{Datum, OutputReference, Redeemer, Transaction}

pub type USDMintAction {
  USDMint { qty: Int }
  USDBurn
}

validator usdR(pkh: ByteArray) {
  mint(r: USDMintAction, p: PolicyId, tx: Transaction) {
    expect [Pair(tokenName, tokenQty)] =
      tx.mint
        |> assets.tokens(p)
        |> dict.to_pairs()
    when r is {
      USDMint { qty } -> {
        expect Some(out) =
          list.find(
            tx.outputs,
            fn(output) {
              output.address.payment_credential == Script(p) && assets.without_lovelace(
                output.value,
              ) == assets.from_asset(p, tokenName, tokenQty)
            },
          )
        tokenName == "" && tokenQty == qty
      }
      USDBurn -> tokenQty < 0
    }
  }

  spend(_d: Option<Datum>, _r: Redeemer, oref: OutputReference, tx: Transaction) {
    True
  }

  else(_) {
    fail
  }
}
