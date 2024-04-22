//                    //
// Rewards Mechanisms //
//                    //

// We will have a rewards minting policy to allow us to mint on demand
// at the point of closing a loan.
// This info will be added to the Loan Datum to be updated every transaction
// If a loan is liquidated then no rewards tokens will be minted

// To make this work in the most modular way, without bloating the contracts
// I think we shuold use the config validator to store the hash of the minting policy,
// That way we can reference tha validator signature rather than checking for the output

//                      //
// Rewards Token Policy //
//                      //

type SConfigDatum {
  loanVal: ScriptHash,
  colVal: ScriptHash,
  rewardsVal: ScriptHash,
}

type RLoanDatum {
  collateral: ByteArray,
  collateralValue: Int,
  loanCurrency: ByteArray,
  loanValue: Int,
  rewards: Int,
  timestamp: PosixTime,
}

type RewwardsAction {
  RewardMint,
  RewardBurn,
}

validator(cp: PolicyId, o: VerificationKeyHash) {
  // config policy
  fn rewardsMint(r: RewardsAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Mint(policyId) = purpose
    let Transaction { mint, outputs, .. } = transaction

    expect Some(refIn) =
      find(
        transaction.reference_inputs,
        fn(input) { has(policies(input.output.value), c) },
      )
    expect InlineDatum(datum) = refIn.output.datum
    expect cDatum: SConfigDatum = datum

    expect [(tName, tAmt)] =
      mint
        |> value.from_minted_value()
        |> value.tokens(policyId)
        |> dict.to_list()

    when r is {
      RewardMint -> {
        let loanIn =
          find(
            transaction.inputs,
            fn(input) { has(policies(input.output.value), c) },
          )

        expect InlineDatum(datum) = loanIn.output.datum
        expect lDatum: RLoanDatum = datum

        expect [] = find_script_outputs(outputs, cDatum.loanVal)

        tAmt == lDatum.rewards
      }

      RewardBurn -> has(transaction.extra_signatories, o) && tAmt <= -1
    }
  }
}

// Additions To Loan Validator //

// we need a minting rewards case for the loan when it is closed

//                 //
// Init Loan Vault //
//                 //

validator(p: PolicyId, o: PolicyId, cp: PolicyId) {
  fn loanVault(d: LoanDatum, r: LoanAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Spend(oref) = purpose

    let Transaction { inputs, outputs, reference_inputs, .. } = transaction

    expect Some(refIn) =
      find(reference_inputs, fn(input) { has(policies(input.output.value), o) })

    expect InlineDatum(datum) = refIn.output.datum
    expect rDatum: OracleDatum = datum
    let exchangeRate = rDatum.usdAda

    when r.a is {
      1 -> {
        // balance
        let ownOut = get_own_singleton_output(transaction, oref)
        let adaOut = lovelace_of(ownOut.value) / 1000000
        let newCollateralValue = adaOut / exchangeRate
        let minCollateralValue = d.loanValue * exchangeRate * ( 50 / 100 )
        expect has(policies(ownOut.value), p)
        expect InlineDatum(datum) = ownOut.datum
        expect datum: LoanDatum = datum

        datum.collateral == d.collateral && datum.collateralValue == newCollateralValue && datum.loanCurrency == d.loanCurrency && datum.loanValue == d.loanValue && datum.timestamp == r.b && adaOut >= minCollateralValue
      }

      2 -> {
        // liquidate
        let ownOut = get_own_singleton_output(transaction, oref)
        let adaOut = lovelace_of(ownOut.value) / 1000000
        let newCollateralValue = adaOut / exchangeRate
        expect has(policies(ownOut.value), p)
        expect InlineDatum(datum) = ownOut.datum
        expect datum: LoanDatum = datum
        let minCollateralValue = datum.loanValue * exchangeRate * ( 85 / 100 )

        datum.collateral == d.collateral && datum.collateralValue == newCollateralValue && datum.loanCurrency == d.loanCurrency && datum.loanValue == d.loanValue - r.c && datum.timestamp == r.b && adaOut >= minCollateralValue
      }
      // close
      _ -> {
        expect Some(refConfig) =
          find(
            reference_inputs,
            fn(input) { has(policies(input.output.value), cp) },
          )

        expect InlineDatum(datum) = refConfig.output.datum
        expect cDatum: SConfigDatum = datum
        let rewardsHash = cDatum.rewardsVal

        has(extra_signatories, rewardsHash) && d.loanValue == 0
      }
    }
  }
}
