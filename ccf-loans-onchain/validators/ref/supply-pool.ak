// Supply Pool

// in order to allow people to supply their own assets for lending, we need to 
// create a pool for users to supply to, but in order to do that we will need to 
// track an individuals contributions and allow them to manage their value at any 
// given point
// we could have a system where users add to a single utxo, but that might affect 
// tracking rewards, making that a little complicated
// we could use a more complex design pattern like a linked list
// for now we will use a single thread, and we will need to implement chaining

pub type SupplyAction {
  SSupply { value: Int }
  SLend { value: Int }
  SWithdraw { value: Int }
  SClose
}

pub type SupplyDatum {
  policy: PolicyId,
  asset: AssetName
  oracle: ByteArray
}

validator supplyPool(owner: ByteArray, op: PolicyId) {
  spend(
    datum: Option<SupplyDatum>,
    r: SupplyAction,
    oref: OutputReference,
    tx: Transaction,
  ) {
    expect Some(d) = datum
    expect Some(ownInput) =
      list.find(tx.inputs, fn(input) { input.output_reference == oref })

    let supplyToken = datum.policy

    when r is {
      SSupply { value } -> {
        expect [Pair(lpName, lpAmt)] = 
          tx.mint 
            |> assets.tokens(lp)
            |> dict.to_pairs()

        expect Some(ownOut) = 
          list.find(
            tx.outputs,
            fn(output) {
              output.address.payment_credential == ownInput.output.address.payment_credential
            }
          )

        expect newValue = 
          assets.merge(
            ownInput.value,
            assets.from_asset(policy, name, value)
          )

        expect InlineDatum(datum) = ownOut.datum
        expect outDatum: SupplyDatum = datum

        expect Some(oracleIn) = 
          list.find(
            tx.inputs,
            fn(input) {
              list.has(assets.policies(input.output.value), op)
            }
          )

        expect InlineDatum(datum) = oracleIn.datum
        expect oIn: OracleDatum = datum 

        expect Some(oracleOut) = 
          list.find(
            tx.outputs,
            fn(output) {
              output.address == oracleIn.output.address
            }
          )
        
        expect InlineDatum(datum) = oracleOut.datum 
        expect oOut: OracleDatum = datum 
        
        and {
          newValue == ownOut.value,
          d.policy == outDatum.policy,
          d.asset == outDatum.asset,
          d.oracle == outDatum.oracle,
          oOut.supply == oIn.supply + value,
          lpName == "",
          lpAmt == value,
        }
      }
      SLend -> {
        expect Some(ownOut) = 
          list.find(
            tx.outputs,
            fn(output) {
              output.address.payment_credential == ownInput.output.address.payment_credential
            }
          )
        
        expect InlineDatum(datum) = ownOut.datum
        expect outDatum: SupplyDatum = datum

        expect newValue = 
          assets.merge(
            ownInput.value,
            assets.from_asset(policy, name, (0 - value))
          )

        expect [Pair(loanName, loanAmt)] = 
          tx.mint 
            |> assets.tokens(lp)
            |> dict.to_pairs()
        
        expect Some(loanOut) = 
          list.find(
            tx.outputs,
            fn(output) {
              output.address.payment_credential == loanHash
            }
          )
        
        expect [Pair(lOutName, lOutAmt)] = 
          loanOut.value
            |> assets.tokens(lp)
            |> dict.to_pairs()
          
        expect InlineDatum(datum) = loanOut.datum
        expect lDatum: LoanDatum = datum

        expect Some(oracleIn) = 
          list.find(
            tx.inputs,
            fn(input) {
              list.has(assets.policies(input.output.value), op)
            }
          )

        expect InlineDatum(datum) = oracleIn.datum
        expect oIn: OracleDatum = datum 

        expect Some(oracleOut) = 
          list.find(
            tx.outputs,
            fn(output) {
              output.address == oracleIn.output.address
            }
          )
        
        expect InlineDatum(datum) = oracleOut.datum 
        expect oOut: OracleDatum = datum 

        and {
          oOut.borrowed == oIn.borrowed + value,
          lDatum.amount == value,
        }          
        // Sends to recipientAddress -> verified by mLoanMint
        // matches loanMintValue
        // returns the rest of the value to validator
      }
      SWithdraw -> {
        expect [Pair(lpName, lpAmt)] = 
          tx.mint 
            |> assets.tokens(lp)
            |> dict.to_pairs()
        // removes value and burns LP tokens
        expect Some(oracleIn) = 
          list.find(
            tx.inputs,
            fn(input) {
              list.has(assets.policies(input.output.value), op)
            }
          )

        expect InlineDatum(datum) = oracleIn.datum
        expect oIn: OracleDatum = datum 

        expect Some(oracleOut) = 
          list.find(
            tx.outputs,
            fn(output) {
              output.address == oracleIn.output.address
            }
          )
        
        expect InlineDatum(datum) = oracleOut.datum 
        expect oOut: OracleDatum = datum 

        and {
          lpName == "",
          lpAme == 0 - value,
          oIn.supply == oOut.supply + value,
        }
      }
      SClose -> {
        // has no tokens in pool
        // oracle is burned
        True
      }
    }
  }

  else(_) {
    fail
  }
}

validator supplyMint() {
  mint(r: SupplyMintAction, p: PolicyId, tx: Transaction) {
    expect [Pair(lpName, lpAmt)] = 
      tx.mint 
        |> assets.tokens(p)
        |> dict.to_pairs()

    when r is {
      LPMint { value } -> True
      LPBurn -> True 
    }
  }
}