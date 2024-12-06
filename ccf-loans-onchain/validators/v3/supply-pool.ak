use aiken/collection/dict
use aiken/collection/list
use aiken/crypto.{ScriptHash}
use cardano/address.{Script}
use cardano/assets.{PolicyId}
use cardano/transaction.{InlineDatum, OutputReference, Transaction}
use ccfl/types.{
  LPBurn, LPMint, LoanDatum, OracleDatum, SClose, SLend, SSupply, SWithdraw,
  SupplyAction, SupplyDatum, SupplyMintAction,
}

// Supply Pool //

// in order to allow people to supply their own assets for lending, we need to 
// create a pool for users to supply to, but in order to do that we will need to 
// track an individuals contributions and allow them to manage their value at any 
// given point
// we could have a system where users add to a single utxo, but that might affect 
// tracking rewards, making that a little complicated
// we could use a more complex design pattern like a linked list
// for now we will use a single thread, and we will need to implement chaining

validator supplyPool(owner: ByteArray, op: PolicyId, loanHash: ScriptHash) {
  mint(r: SupplyMintAction, p: PolicyId, tx: Transaction) {
    expect [Pair(lpName, lpAmt)] =
      tx.mint
        |> assets.tokens(p)
        |> dict.to_pairs()

    expect Some(ownInput) =
      list.find(
        tx.inputs,
        fn(input) { input.output.address.payment_credential == Script(p) },
      )

    expect Some(oracleIn) =
      list.find(
        tx.inputs,
        fn(input) { list.has(assets.policies(input.output.value), op) },
      )

    expect InlineDatum(datum) = oracleIn.output.datum
    expect oIn: OracleDatum = datum

    expect Some(oracleOut) =
      list.find(
        tx.outputs,
        fn(output) { output.address == oracleIn.output.address },
      )
    expect InlineDatum(datum) = oracleOut.datum
    expect oOut: OracleDatum = datum

    when r is {
      LPMint { value } -> and {
          lpName == "",
          lpAmt == value,
          oOut.supply == oIn.supply + value,
        }
      LPBurn -> and {
          lpName == "",
          lpAmt == oOut.supply - oIn.supply,
        }
    }
  }

  spend(
    datum: Option<SupplyDatum>,
    r: SupplyAction,
    oref: OutputReference,
    tx: Transaction,
  ) {
    expect Some(d) = datum
    expect Some(ownInput) =
      list.find(tx.inputs, fn(input) { input.output_reference == oref })

    expect Script(ownHash) = ownInput.output.address.payment_credential

    let supplyToken = d.policy

    expect Some(oracleIn) =
      list.find(
        tx.inputs,
        fn(input) { list.has(assets.policies(input.output.value), op) },
      )

    expect InlineDatum(datum) = oracleIn.output.datum
    expect oIn: OracleDatum = datum

    when r is {
      SSupply { value } -> {
        expect Some(oracleOut) =
          list.find(
            tx.outputs,
            fn(output) { output.address == oracleIn.output.address },
          )
        expect InlineDatum(datum) = oracleOut.datum
        expect oOut: OracleDatum = datum

        expect [Pair(lpName, lpAmt)] =
          tx.mint
            |> assets.tokens(ownHash)
            |> dict.to_pairs()

        expect Some(ownOut) =
          list.find(
            tx.outputs,
            fn(output) {
              output.address.payment_credential == ownInput.output.address.payment_credential
            },
          )

        expect newValue =
          assets.merge(
            ownInput.output.value,
            assets.from_asset(d.policy, d.asset, value),
          )

        expect InlineDatum(datum) = ownOut.datum
        expect outDatum: SupplyDatum = datum

        and {
          lpName == "",
          lpAmt == value,
          newValue == ownOut.value,
          d.policy == outDatum.policy,
          d.asset == outDatum.asset,
          d.oracle == outDatum.oracle,
          oOut.supply == oIn.supply + value,
        }
      }
      SLend { value } -> {
        expect Some(oracleOut) =
          list.find(
            tx.outputs,
            fn(output) { output.address == oracleIn.output.address },
          )
        expect InlineDatum(datum) = oracleOut.datum
        expect oOut: OracleDatum = datum

        expect Some(ownOut) =
          list.find(
            tx.outputs,
            fn(output) {
              output.address.payment_credential == ownInput.output.address.payment_credential
            },
          )
        expect InlineDatum(datum) = ownOut.datum
        expect outDatum: SupplyDatum = datum

        expect newValue =
          assets.merge(
            ownInput.output.value,
            assets.from_asset(d.policy, d.asset, 0 - value),
          )

        expect Some(loanOut) =
          list.find(
            tx.outputs,
            // need to access loanHash from ConfigDatum OR Params
            fn(output) { output.address.payment_credential == Script(loanHash) },
          )

        expect [Pair(lOutName, lOutAmt)] =
          loanOut.value
            |> assets.tokens(loanHash)
            |> dict.to_pairs()

        expect InlineDatum(datum) = loanOut.datum
        expect lDatum: LoanDatum = datum

        // expect Some(userOut) =
        //   list.find(
        //     tx.outputs,
        //     fn(output) { output.address.payment_credential == lDatum.user },
        //   )
        and {
          oOut.borrowed == oIn.borrowed + value,
          lDatum.amount == value,
          lOutAmt == 1,
        }
      }
      // Sends to recipientAddress -> verified by mLoanMint
      // matches loanMintValue
      // returns the rest of the value to validator
      SWithdraw { value } -> {
        expect Some(oracleOut) =
          list.find(
            tx.outputs,
            fn(output) { output.address == oracleIn.output.address },
          )
        expect InlineDatum(datum) = oracleOut.datum
        expect oOut: OracleDatum = datum

        expect [Pair(lpName, lpAmt)] =
          tx.mint
            |> assets.tokens(ownHash)
            |> dict.to_pairs()

        expect Some(userIn) =
          list.find(
            tx.inputs,
            fn(input) { list.has(assets.policies(input.output.value), ownHash) },
          )
        // input.output.address.payment_credential == VerificationKey(_)
        expect [Pair(inName, inAmt)] =
          userIn.output.value
            |> assets.tokens(ownHash)
            |> dict.to_pairs()

        expect Some(userOut) =
          list.find(
            tx.outputs,
            fn(output) {
              output.address.payment_credential == userIn.output.address.payment_credential
            },
          )

        trace inAmt
        trace value

        if inAmt > value {
          expect [Pair(outName, outAmt)] =
            userOut.value
              |> assets.tokens(ownHash)
              |> dict.to_pairs()

          and {
            outName == "",
            outAmt == inAmt - value,
            lpName == "",
            lpAmt == 0 - value,
            oIn.supply == oOut.supply + value,
            inName == "",
            inAmt >= value,
          }
        } else if inAmt == value {
          and {
            lpName == "",
            lpAmt == 0 - value,
            oIn.supply == oOut.supply + value,
            inName == "",
            inAmt >= value,
          }
        } else {
          fail
        }
      }
      // removes value and burns LP tokens
      SClose -> {
        expect tokenValue =
          assets.quantity_of(ownInput.output.value, d.policy, d.asset)

        expect [Pair(oName, oAmt)] =
          tx.mint
            |> assets.tokens(op)
            |> dict.to_pairs()

        and {
          tokenValue == 0,
          oIn.borrowed == 0,
          oIn.supply == 0,
          oAmt == -2,
        }
      }
    }
    // has no tokens in pool
    // oracle is burned
  }

  else(_) {
    fail
  }
}
