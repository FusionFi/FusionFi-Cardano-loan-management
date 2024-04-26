use aiken/dict.{to_list, values}
use aiken/hash.{Blake2b_224, Hash}
use aiken/list.{any, filter, find, has, head}
use aiken/time.{PosixTime}
use aiken/transaction.{
  InlineDatum, Input, Mint, Output, OutputReference, ScriptContext, Spend,
  Transaction, find_input, find_script_outputs,
}
use aiken/transaction/credential.{
  Credential, PaymentCredential, Script, ScriptCredential, VerificationKey,
  VerificationKeyCredential,
}
use aiken/transaction/value.{
  PolicyId, flatten, from_minted_value, lovelace_of, policies, quantity_of,
  tokens, without_lovelace,
}

//         //
// Helpers //
//         //

fn get_own_singleton_output(tx: Transaction, oref: OutputReference) -> Output {
  expect Some(input) =
    tx.inputs
      |> find_input(oref)

  expect ScriptCredential(script_hash) = input.output.address.payment_credential
  let script_outputs =
    tx.outputs
      |> find_script_outputs(script_hash)

  expect list.length(script_outputs) == 1
  expect Some(output) =
    tx.outputs
      |> find_script_outputs(script_hash)
      |> list.head()
  output
}

fn calculate_rate(last: PosixTime, new: PosixTime, rate: Int) -> Int {
  let day = 86400
  let diff = new - last
  let daysToCharge = diff / day
  let dailyRate = rate / 365
  let apr = dailyRate * daysToCharge

  apr
}

type VerificationKeyHash =
  Hash<Blake2b_224, VerificationKey>

type ScriptHash =
  Hash<Blake2b_224, Script>

//                     //
// Datums && Redeemers //
//                     //

type ConfigDatum {
  loanVal: ScriptHash,
  colVal: ScriptHash,
  rewardsVal: ScriptHash,
}

type ConfigAction {
  ConUpdate { loanVal: ScriptHash, colVal: ScriptHash, rewardsVal: ScriptHash }
  ConClose
}

type LoanAction {
  SLBalance
  SLLiquidate
  SLClose
}

type LoanMintAction {
  AMint { loanCurrency: ByteArray, loanValue: Int, timestamp: PosixTime }
  ABurn
}

type LoanDatum {
  amount: Int,
  interest: Int,
  rewards: Int,
  term: Int,
  timestamp: PosixTime,
}

type CollateralAction {
  SCBalance
  SCLiquidate
  SCClose
}

type CollateralDatum {
  amount: Int,
  timestamp: PosixTime,
}

type RewardsAction {
  RewardMint
  RewardBurn
}

type OracleDatum {
  usdAda: Int,
  timestamp: PosixTime,
  rate: Int,
  fee: Int,
}

type OracleAction {
  OracleUpdate { usdAda: Int, timestamp: PosixTime, rate: Int, fee: Int }
  OracleClose
}

type OracleMintAction {
  OMint
  OBurn
}

//                  //
// Oracle Validator //
//                  //

validator(o: VerificationKeyHash, p: PolicyId) {
  fn oracleVault(d: OracleDatum, r: OracleAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Spend(ownRef) = purpose

    when r is {
      OracleUpdate { usdAda, timestamp, rate, fee } -> {
        // check own output
        let out = get_own_singleton_output(transaction, ownRef)
        // expect single token ignoring Token Name
        expect [(_, 1)] =
          without_lovelace(out.value)
            |> tokens(p)
            |> to_list()
        // expect variable oracle datum
        expect InlineDatum(datum) = out.datum
        expect datum: OracleDatum = datum
        // signed by owner
        has(transaction.extra_signatories, o) && timestamp > d.timestamp && rate > 0 && fee > 0 && datum.usdAda == usdAda && datum.timestamp == timestamp && datum.rate == rate && datum.fee == fee
      }
      OracleClose -> {
        // get input from oref
        expect Some(input) = find_input(transaction.inputs, ownRef)

        expect [(inName, 1)] =
          // get singleton name
          without_lovelace(input.output.value)
            |> tokens(p)
            |> to_list()
        // expect single token burns in the transaction
        expect [(burnName, -1)] =
          transaction.mint
            |> value.from_minted_value()
            |> value.tokens(p)
            |> dict.to_list()
        // signed by owner
        has(transaction.extra_signatories, o) && inName == burnName
      }
    }
  }
}

//             //
// Oracle Mint //
//             //

validator(o: VerificationKeyHash) {
  fn oracleMint(r: OracleMintAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Mint(policyId) = purpose

    expect [(oName, oAmt)] =
      transaction.mint
        |> from_minted_value()
        |> tokens(policyId)
        |> to_list()

    when r is {
      // checks signed by owner and No. of tokens
      OMint -> list.has(transaction.extra_signatories, o) && oAmt == 1
      OBurn -> list.has(transaction.extra_signatories, o) && oAmt == -1
    }
  }
}

//                  //
// Config Validator //
//                  //

validator(o: VerificationKeyHash, cp: PolicyId) {
  fn configVal(d: ConfigDatum, r: ConfigAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Spend(oref) = purpose

    let Transaction { inputs, outputs, extra_signatories, .. } = transaction

    when r is {
      ConUpdate { loanVal, colVal, rewardsVal } -> {
        // gets own output (ensures there is only one)
        let ownOut = get_own_singleton_output(transaction, oref)
        // checks output datum
        expect InlineDatum(datum) = ownOut.datum
        expect outDatum: ConfigDatum = datum
        // checks signed by owner, has a Config Token Datum values match redeemer
        has(extra_signatories, o) && has(policies(ownOut.value), cp) && outDatum.loanVal == loanVal && outDatum.colVal == colVal
      }
      // checks signed by owner
      ConClose -> has(extra_signatories, o)
    }
  }
}

//                       //
// Config Minting Policy //
//                       //

validator(o: VerificationKeyHash) {
  fn configMint(r: ConfigAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Mint(policyId) = purpose

    let Transaction { outputs, extra_signatories, mint, .. } = transaction

    expect [(tName, tAmt)] =
      mint
        |> value.from_minted_value()
        |> value.tokens(policyId)
        |> dict.to_list()

    when r is {
      ConUpdate { loanVal, colVal, rewardsVal } -> {
        // checks the output with the token
        expect Some(ownOut) =
          find(outputs, fn(output) { has(policies(output.value), policyId) })
        // has the appropriate datum        
        expect InlineDatum(datum) = ownOut.datum
        expect outDatum: ConfigDatum = datum
        // output datum matches redeemer && only 1 token is minted && signed by owner
        outDatum.loanVal == loanVal && outDatum.colVal == colVal && has(
          extra_signatories,
          o,
        ) && tAmt == 1
      }
      // signed by owner and mint amount is -1
      ConClose -> has(extra_signatories, o) && tAmt == -1
    }
  }
}

//                              //
// Rewards Token Minting Policy //
//                              //

validator(o: VerificationKeyHash, cp: PolicyId, lp: PolicyId) {
  fn rewardsMint(r: RewardsAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Mint(policyId) = purpose
    let Transaction { mint, outputs, .. } = transaction

    // checks for config ref input
    expect Some(refIn) =
      find(
        transaction.reference_inputs,
        fn(input) { has(policies(input.output.value), cp) },
      )
    // config input has the right datum
    expect InlineDatum(datum) = refIn.output.datum
    expect cDatum: ConfigDatum = datum

    expect [(tName, tAmt)] =
      mint
        |> value.from_minted_value()
        |> value.tokens(policyId)
        |> dict.to_list()

    when r is {
      RewardMint -> {
        // checks for loan input (need to add LP as param)
        expect Some(loanIn) =
          find(
            transaction.inputs,
            fn(input) { has(policies(input.output.value), lp) },
          )
        // checks datum is correct
        expect InlineDatum(datum) = loanIn.output.datum
        expect lDatum: LoanDatum = datum
        // checks no loan outputs
        expect [] = find_script_outputs(outputs, cDatum.loanVal)
        // checks mint amount == rewards
        tAmt == lDatum.rewards
      }
      // checks burn is -1 or less and tx signed by owner
      RewardBurn -> has(transaction.extra_signatories, o) && tAmt <= -1
    }
  }
}

//                    //
// Separate Loan Mint //
//                    //

// Mints 2 tokens 
// sends one to loan vault with datum
// sends one to collateral vault with datum

validator(op: PolicyId, cp: PolicyId) {
  fn loanMint(r: LoanMintAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Mint(policyId) = purpose

    let Transaction { mint, outputs, reference_inputs, .. } = transaction

    expect [(tName, tAmt)] =
      mint
        |> value.from_minted_value()
        |> value.tokens(policyId)
        |> dict.to_list()

    when r is {
      AMint { loanCurrency, loanValue, timestamp } -> {
        // checks for Oracle ref in
        expect Some(oracleOut) =
          find(outputs, fn(output) { has(policies(output.value), op) })
        // checks oracle datum
        expect InlineDatum(datum) = oracleOut.datum
        expect rDatum: OracleDatum = datum
        // pulls exchange rate
        let exchangeRate = rDatum.usdAda
        // checks for config input
        expect Some(configIn) =
          head(
            filter(
              reference_inputs,
              fn(ref) { has(policies(ref.output.value), cp) },
            ),
          )
        // checks config datum
        expect InlineDatum(datum) = configIn.output.datum
        expect cDatum: ConfigDatum = datum
        // sends to loan validator in config
        expect Some(loanOut) =
          find(
            outputs,
            fn(output) {
              output.address.payment_credential == ScriptCredential(
                cDatum.loanVal,
              ) && has(policies(output.value), policyId)
            },
          )
        // sends to collateral validator in config
        expect Some(colOut) =
          find(
            outputs,
            fn(output) {
              output.address.payment_credential == ScriptCredential(
                cDatum.colVal,
              ) && has(policies(output.value), policyId)
            },
          )
        // checks loan output datum
        expect InlineDatum(datum) = loanOut.datum
        expect lDatum: LoanDatum = datum
        // checks collateral output datum
        expect InlineDatum(datum) = colOut.datum
        expect cDatum: CollateralDatum = datum
        // checks loan values against redeemer && collateral && 2 tokens minted
        lDatum.amount == loanValue && lDatum.interest == 15 && lDatum.term == 0 && cDatum.amount == loanValue * 2 && lovelace_of(
          colOut.value,
        ) >= lDatum.amount * exchangeRate * 1000000 && tAmt == 2
      }
      // always allows Burn -> This needs to be changed to only allow burning when the loan is 
      // closed or there is no more loan value (ie liquidated)
      ABurn -> True
    }
  }
}

//                     //
// Separate Loan Vault //
//                     //

// Loan Vault holds the loan information at a token utxo

validator(op: PolicyId, lp: PolicyId, cp: PolicyId) {
  fn loanVal(d: LoanDatum, r: LoanAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Spend(oref) = purpose

    let Transaction { inputs, outputs, reference_inputs, .. } = transaction
    // checks for oracle input
    expect Some(oracleOut) =
      find(outputs, fn(output) { has(policies(output.value), op) })
    // checks oracle datum
    expect InlineDatum(datum) = oracleOut.datum
    expect rDatum: OracleDatum = datum
    // gets exchange rate
    let exchangeRate = rDatum.usdAda
    // checks for Config input
    expect Some(configIn) =
      find(
        reference_inputs,
        fn(input) { has(policies(input.output.value), cp) },
      )
    // checks Config Datum
    expect InlineDatum(datum) = configIn.output.datum
    expect cDatum: ConfigDatum = datum

    when r is {
      SLBalance -> {
        // Balance Loan, get own input
        expect Some(ownIn) = find_input(inputs, oref)
        // check for loan token
        expect Some(loanToken) =
          head(flatten(without_lovelace(ownIn.output.value)))
        // check collateral output
        expect Some(colOut) =
          find(
            outputs,
            fn(output) {
              // check for collateral token
              expect Some(colToken) =
                head(flatten(without_lovelace(output.value)))
              // script hash matches config Datum
              output.address.payment_credential == ScriptCredential(
                cDatum.colVal,
              ) && loanToken == colToken
            },
          )
        // checks for collateral datum
        expect InlineDatum(datum) = colOut.datum
        expect cDatum: CollateralDatum = datum
        // find own output
        let ownOut = get_own_singleton_output(transaction, oref)
        // value in ADA
        let adaOut = lovelace_of(colOut.value) / 1000000
        // new value acc Exchange rate
        let newCollateralValue = adaOut / exchangeRate
        // minimum expected collateral value
        let minCollateralValue = d.amount * exchangeRate * ( 50 / 100 )
        // own out has loan Token
        expect has(policies(ownOut.value), lp)
        // check own output datum
        expect InlineDatum(datum) = ownOut.datum
        expect datum: LoanDatum = datum
        // check datum values && ADA collateral output
        datum.amount == d.amount && datum.interest == d.interest && datum.term == d.term && adaOut >= minCollateralValue
      }

      SLLiquidate -> {
        // Liquidate Loan
        // get own input
        expect Some(ownIn) = find_input(inputs, oref)
        // check for loan token
        expect Some(loanToken) =
          head(flatten(without_lovelace(ownIn.output.value)))
        // check for collateral output
        expect Some(colOut) =
          find(
            outputs,
            fn(output) {
              expect Some(colToken) =
                head(flatten(without_lovelace(output.value)))
              // script hash matches config Datum
              output.address.payment_credential == ScriptCredential(
                cDatum.colVal,
              ) && // make sure the loan token is the same as the collateral token
              loanToken == colToken
            },
          )
        // check collateral datum
        expect InlineDatum(datum) = colOut.datum
        expect cDatum: CollateralDatum = datum
        // get own output
        let ownOut = get_own_singleton_output(transaction, oref)
        // calc ADA value
        let adaOut = lovelace_of(colOut.value) / 1000000
        // new value acc Exchange rate
        let newCollateralValue = adaOut / exchangeRate
        expect has(policies(ownOut.value), lp)
        // check own output datum
        expect InlineDatum(datum) = ownOut.datum
        expect datum: LoanDatum = datum
        // minimum expected collateral value
        let minCollateralValue = datum.amount * exchangeRate * ( 85 / 100 )

        datum.amount == d.amount && datum.interest == d.interest && datum.term == d.term && adaOut >= minCollateralValue
      }
      // close
      SLClose -> d.amount == 0
    }
  }
}

//                           //
// Separate Collateral Vault //
//                           //

validator(op: PolicyId, lp: PolicyId, cp: PolicyId) {
  fn collateralVal(
    d: CollateralDatum,
    r: CollateralAction,
    c: ScriptContext,
  ) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Spend(oref) = purpose

    let Transaction { inputs, outputs, reference_inputs, .. } = transaction

    // check Oracle ref input
    expect Some(oracleOut) =
      find(outputs, fn(output) { has(policies(output.value), op) })
    // check oracle datum
    expect InlineDatum(datum) = oracleOut.datum
    expect rDatum: OracleDatum = datum
    // extract exchange Rate
    let exchangeRate = rDatum.usdAda

    // Get config ref input
    expect Some(configIn) =
      find(
        reference_inputs,
        fn(input) { has(policies(input.output.value), cp) },
      )
    // check config datum
    expect InlineDatum(datum) = configIn.output.datum
    expect cDatum: ConfigDatum = datum

    when r is {
      SCBalance -> {
        // get own input
        expect Some(ownIn) = find_input(inputs, oref)
        // check collateral token
        expect Some(collateralToken) =
          head(flatten(without_lovelace(ownIn.output.value)))
        // check for loan output
        expect Some(loanOut) =
          find(
            outputs,
            fn(output) {
              // check for loan token
              expect Some(loanToken) =
                head(flatten(without_lovelace(output.value)))
              // script hash matches config Datum
              output.address.payment_credential == ScriptCredential(
                cDatum.loanVal,
              ) && // make sure the loan token is the same as the collateral token
              loanToken == collateralToken
            },
          )
        // extract loan datum
        expect InlineDatum(datum) = loanOut.datum
        expect lDatum: LoanDatum = datum
        // get own output
        let ownOut = get_own_singleton_output(transaction, oref)
        // check it has the right datum
        expect InlineDatum(datum) = ownOut.datum
        expect outDatum: CollateralDatum = datum
        // check the value of the collateral is greater than the minimum
        lovelace_of(ownOut.value) >= lDatum.amount * exchangeRate * ( 50 / 100 ) * 1000000 && outDatum.amount == lovelace_of(
          ownOut.value,
        ) / exchangeRate / 1000000 && has(
          // own output has collateral token
          flatten(ownOut.value),
          collateralToken,
        )
      }
      // && outDatum.timestamp == timestamp
      SCLiquidate -> {
        // get own input
        expect Some(ownIn) = find_input(inputs, oref)
        // check for collateral token
        expect Some(collateralToken) =
          head(flatten(without_lovelace(ownIn.output.value)))
        // check for loan output
        expect Some(loanOut) =
          find(
            outputs,
            fn(output) {
              // check for loan token
              expect Some(loanToken) =
                head(flatten(without_lovelace(output.value)))
              // script hash matches config Datum loan Validator
              output.address.payment_credential == ScriptCredential(
                cDatum.loanVal,
              ) && // make sure the loan token is the same as the collateral token
              loanToken == collateralToken
            },
          )
        // check loan datum
        expect InlineDatum(datum) = loanOut.datum
        expect lDatum: LoanDatum = datum
        // get own output
        let ownOut = get_own_singleton_output(transaction, oref)
        // check own output datum
        expect InlineDatum(datum) = ownOut.datum
        expect outDatum: CollateralDatum = datum
        // check the value of the collateral is greater than the minimum
        lovelace_of(ownOut.value) >= lDatum.amount * exchangeRate * ( 50 / 100 ) * 1000000 && outDatum.amount == lovelace_of(
          ownOut.value,
        ) / exchangeRate / 1000000 && has(
          // output has collateral token
          flatten(ownOut.value),
          collateralToken,
        )
      }
      // && outDatum.timestamp == timestamp
      SCClose -> True
    }
  }
}
