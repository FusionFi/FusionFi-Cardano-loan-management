pub type LoanDatum {
  LoanDatum
}

pub type FiatMintAction {
  FMint { amount: Int, rewards: Int, term: Int, timestamp: Int, pkh: ByteArray }
  FBurn
}

validator loanMint(cp: PolicyId) {
  mint(r: FiatMintAction, p: PolicyId, tx: Transaction) {
    expect [Pair(loanToken, loanQty)] =
      tx.mint
        |> assets.tokens(p)
        |> dict.to_pairs()

    let cDatum: MerkelConfigDatum = h.get_config_datum(tx.reference_inputs, cp)

    when r is {
      FMint -> {
        expect Some(fiatLend) =
          cDatum.supplyRedeemers
            |> list.at(r.i)

        expect Some(ownOut)
        list.find(
          tx.outputs,
          fn(out) { out.address.script_credential == Script(p) },
        )

        and {
          pairs.has_key(tx.withdrawals, Script(fiatLend)),
          loanQty == 2,
        }
      }
      FBurn -> {
        expect Some(close) = cDatum.collateralRedeemers |> list.at(r.i)

        and {
          pairs.has_key(tx.withdrawals, Script(close)),
          loanQty == -2,
        }
      }
    }
    // has no tokens in pool
    // oracle is burned
  }

  spend(
    _d: Option<LoanDatum>,
    r: MerkelLoanAction,
    _oref: OutputReference,
    tx: Transaction,
  ) {
    let cDatum: MerkelConfigDatum =
      helpers.get_config_datum(tx.reference_inputs, cp)

    expect Some(stakeVal) =
      cDatum.collateralRedeemers
        |> list.at(r.i)

    pairs.has_key(tx.withdrawals, Script(stakeVal))
  }

  else(_) {
    fail
  }
}
