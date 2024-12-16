use aiken/collection/dict
use aiken/collection/list
use aiken/collection/pairs
use cardano/address.{Script}
use cardano/assets.{PolicyId}
use cardano/transaction.{OutputReference, Transaction}
use ccfl/helpersv3 as h
use ccfl/typesv3.{MerkelConfigDatum, MerkelLoanAction}

pub type LoanDatum {
  LoanDatum
}

pub type FiatMintAction {
  FMint { i: Int }
  FBurn { i: Int }
}

validator loanMint(cp: PolicyId) {
  mint(r: FiatMintAction, p: PolicyId, tx: Transaction) {
    expect [Pair(_loanToken, loanQty)] =
      tx.mint
        |> assets.tokens(p)
        |> dict.to_pairs()

    let cDatum: MerkelConfigDatum = h.get_config_datum(tx.reference_inputs, cp)

    when r is {
      FMint { i } -> {
        expect Some(fiatLend) =
          cDatum.supplyRedeemers
            |> list.at(i)

        expect Some(_ownOut) =
          list.find(
            tx.outputs,
            fn(out) { out.address.payment_credential == Script(p) },
          )

        and {
          pairs.has_key(tx.withdrawals, Script(fiatLend)),
          loanQty == 2,
        }
      }
      FBurn { i } -> {
        expect Some(close) = cDatum.collateralRedeemers |> list.at(i)

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
    let cDatum: MerkelConfigDatum = h.get_config_datum(tx.reference_inputs, cp)

    expect Some(stakeVal) =
      cDatum.collateralRedeemers
        |> list.at(r.i)

    pairs.has_key(tx.withdrawals, Script(stakeVal))
  }

  else(_) {
    fail
  }
}
