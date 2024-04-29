use aiken/dict.{to_list}
use aiken/hash.{Blake2b_224, Hash}
use aiken/list.{any, filter, find, has, head}
use aiken/time.{PosixTime}
use aiken/transaction.{
  InlineDatum, Input, Mint, NoDatum, Output, OutputReference, ScriptContext,
  Spend, Transaction, find_input, find_script_outputs, placeholder,
}
use aiken/transaction/credential.{Script, ScriptCredential, VerificationKey}
use aiken/transaction/value.{
  PolicyId, flatten, from_minted_value, lovelace_of, policies, tokens,
  without_lovelace,
}
use tests/tools as t

// TODO: Write tests for
// alt redeemers - burn / liquidate / close
// exhaustive failing tests for loan && collateral validators
// and all alt redeemer cases

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

// fn calculate_rate(last: PosixTime, new: PosixTime, rate: Int) -> Int {
//   let day = 86400
//   let diff = new - last
//   let daysToCharge = diff / day
//   let dailyRate = rate / 365
//   let apr = dailyRate * daysToCharge

//   apr
// }

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
        expect colDatum: CollateralDatum = datum
        // checks loan values against redeemer && collateral && 2 tokens minted
        lDatum.amount == loanValue && lDatum.interest == 15 && lDatum.term == 0 && colDatum.amount == loanValue * 2 && lovelace_of(
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

//       //
// Tests //
//       //

// Oracle Val Tests 
test oracle_vault() {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)

  let oracleDatum1 = oracleDatum(1, 11111111, 15, 2)
  let oracleDatum2 = oracleDatum(2, 11111112, 15, 2)
  let inDatum = InlineDatum(oracleDatum1)
  let outDatum = InlineDatum(oracleDatum2)

  let oracleInput =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(t.oracleValHash),
        t.oracleValue(),
        inDatum,
      ),
    )

  let oracleOutput =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      t.oracleValue(),
      outDatum,
    )

  let oracleAction = oracleAction(2, 11111112, 15, 2)

  let tx =
    Transaction {
      ..placeholder(),
      extra_signatories: [test_owner],
      inputs: [oracleInput],
      outputs: [oracleOutput],
    }

  let ctx = ScriptContext { purpose: Spend(oref), transaction: tx }

  oracleVault(test_owner, t.oracleMintHash, oracleDatum1, oracleAction, ctx)?
}

test oracle_vault_datum_fail() fail {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)

  let oracleDatum1 = oracleDatum(1, 11111111, 15, 2)
  let oracleDatum2 = oracleDatum(1, 11111112, 15, 2)
  let inDatum = InlineDatum(oracleDatum1)
  let outDatum = InlineDatum(oracleDatum2)

  let oracleInput =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(t.oracleValHash),
        t.oracleValue(),
        inDatum,
      ),
    )

  let oracleOutput =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      t.oracleValue(),
      outDatum,
    )

  let oracleAction = oracleAction(2, 11111112, 15, 2)

  let tx =
    Transaction {
      ..placeholder(),
      extra_signatories: [test_owner],
      inputs: [oracleInput],
      outputs: [oracleOutput],
    }

  let ctx = ScriptContext { purpose: Spend(oref), transaction: tx }

  oracleVault(test_owner, t.oracleMintHash, oracleDatum1, oracleAction, ctx)?
}

test oracle_vault_redeemer_fail() fail {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)

  let oracleDatum1 = oracleDatum(1, 11111111, 15, 2)
  let oracleDatum2 = oracleDatum(2, 11111112, 15, 2)
  let inDatum = InlineDatum(oracleDatum1)
  let outDatum = InlineDatum(oracleDatum2)

  let oracleInput =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(t.oracleValHash),
        t.oracleValue(),
        inDatum,
      ),
    )

  let oracleOutput =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      t.oracleValue(),
      outDatum,
    )

  let oracleAction = oracleAction(1, 11111112, 15, 2)

  let tx =
    Transaction {
      ..placeholder(),
      extra_signatories: [test_owner],
      inputs: [oracleInput],
      outputs: [oracleOutput],
    }

  let ctx = ScriptContext { purpose: Spend(oref), transaction: tx }

  oracleVault(test_owner, t.oracleMintHash, oracleDatum1, oracleAction, ctx)?
}

test oracle_vault_sig_fail() fail {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)

  let oracleDatum1 = oracleDatum(1, 11111111, 15, 2)
  let oracleDatum2 = oracleDatum(2, 11111112, 15, 2)
  let inDatum = InlineDatum(oracleDatum1)
  let outDatum = InlineDatum(oracleDatum2)

  let oracleInput =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(t.oracleValHash),
        t.oracleValue(),
        inDatum,
      ),
    )

  let oracleOutput =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      t.oracleValue(),
      outDatum,
    )

  let oracleAction = oracleAction(2, 11111112, 15, 2)

  let tx =
    Transaction {
      ..placeholder(),
      extra_signatories: [#"dead"],
      inputs: [oracleInput],
      outputs: [oracleOutput],
    }

  let ctx = ScriptContext { purpose: Spend(oref), transaction: tx }

  oracleVault(test_owner, t.oracleMintHash, oracleDatum1, oracleAction, ctx)?
}

test oracle_vault_token_fail() fail {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)

  let oracleDatum1 = oracleDatum(1, 11111111, 15, 2)
  let oracleDatum2 = oracleDatum(2, 11111112, 15, 2)
  let inDatum = InlineDatum(oracleDatum1)
  let outDatum = InlineDatum(oracleDatum2)

  let oracleInput =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(t.oracleValHash),
        t.oracleValue(),
        inDatum,
      ),
    )

  let oracleOutput =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      t.makeAdaValue(2),
      outDatum,
    )

  let oracleAction = oracleAction(2, 11111112, 15, 2)

  let tx =
    Transaction {
      ..placeholder(),
      extra_signatories: [test_owner],
      inputs: [oracleInput],
      outputs: [oracleOutput],
    }

  let ctx = ScriptContext { purpose: Spend(oref), transaction: tx }

  oracleVault(test_owner, t.oracleMintHash, oracleDatum1, oracleAction, ctx)?
}

// Oracle Mint Tests
test oracle_mint() {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)

  let oracleDatum1 = oracleDatum(1, 11111111, 15, 2)
  let outDatum = InlineDatum(oracleDatum1)

  let ownerInput =
    t.test_input(
      oref,
      t.test_output(t.test_address(test_owner), t.makeAdaValue(10), NoDatum),
    )

  let oracleOutput =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      t.oracleValue(),
      outDatum,
    )

  let tx =
    Transaction {
      ..placeholder(),
      mint: t.oracleMintedValue(),
      extra_signatories: [test_owner],
      inputs: [ownerInput],
      outputs: [oracleOutput],
    }

  let ctx = ScriptContext { purpose: Mint(t.oracleMintHash), transaction: tx }

  oracleMint(test_owner, oracleMintActionMint(), ctx)?
}

test oracle_mint_qty_fail() fail {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)

  let oracleDatum1 = oracleDatum(1, 11111111, 15, 2)
  let outDatum = InlineDatum(oracleDatum1)

  let mintValue =
    value.to_minted_value(
      value.merge(t.oracleTokenValue(), t.oracleTokenValue()),
    )

  let ownerInput =
    t.test_input(
      oref,
      t.test_output(t.test_address(test_owner), t.makeAdaValue(10), NoDatum),
    )

  let oracleOutput =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      t.oracleValue(),
      outDatum,
    )

  let tx =
    Transaction {
      ..placeholder(),
      mint: mintValue,
      extra_signatories: [test_owner],
      inputs: [ownerInput],
      outputs: [oracleOutput],
    }

  let ctx = ScriptContext { purpose: Mint(t.oracleMintHash), transaction: tx }

  oracleMint(test_owner, oracleMintActionMint(), ctx)?
}

test oracle_mint_datum_fail() fail {
  // This passes because we dont guarantee output datum
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)

  let oracleDatum1 = collateralDatum(1, 11111111)
  let outDatum = InlineDatum(oracleDatum1)

  let ownerInput =
    t.test_input(
      oref,
      t.test_output(t.test_address(test_owner), t.makeAdaValue(10), NoDatum),
    )

  let oracleOutput =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      t.oracleValue(),
      outDatum,
    )

  let tx =
    Transaction {
      ..placeholder(),
      mint: t.oracleMintedValue(),
      extra_signatories: [test_owner],
      inputs: [ownerInput],
      outputs: [oracleOutput],
    }

  let ctx = ScriptContext { purpose: Mint(t.oracleMintHash), transaction: tx }

  oracleMint(test_owner, oracleMintActionMint(), ctx)?
}

test oracle_mint_sig_fail() fail {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)

  let oracleDatum1 = oracleDatum(1, 11111111, 15, 2)
  let outDatum = InlineDatum(oracleDatum1)

  let ownerInput =
    t.test_input(
      oref,
      t.test_output(t.test_address(test_owner), t.makeAdaValue(10), NoDatum),
    )

  let oracleOutput =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      t.oracleValue(),
      outDatum,
    )

  let tx =
    Transaction {
      ..placeholder(),
      mint: t.oracleMintedValue(),
      extra_signatories: [#"cafe"],
      inputs: [ownerInput],
      outputs: [oracleOutput],
    }

  let ctx = ScriptContext { purpose: Mint(t.oracleMintHash), transaction: tx }

  oracleMint(test_owner, oracleMintActionMint(), ctx)?
}

// Config Mint Tests
test config_mint() {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)

  let configAction =
    configActionUpdate(t.loanValHash, t.collateralValHash, t.rewardsMintHash)

  let configDatum1 =
    configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
  let outDatum = InlineDatum(configDatum1)

  let ownerInput =
    t.test_input(
      oref,
      t.test_output(t.test_address(test_owner), t.makeAdaValue(10), NoDatum),
    )

  let configOutput =
    t.test_output(
      t.test_script_address(t.configValHash),
      t.configValue(),
      outDatum,
    )

  let tx =
    Transaction {
      ..placeholder(),
      mint: t.configMintedValue(),
      extra_signatories: [test_owner],
      inputs: [ownerInput],
      outputs: [configOutput],
    }

  let ctx = ScriptContext { purpose: Mint(t.configMintHash), transaction: tx }

  configMint(test_owner, configAction, ctx)?
}

test config_mint_qty_fail() fail {
  let test_owner = #"face"

  let mintValue =
    value.to_minted_value(
      value.merge(t.configTokenValue(), t.configTokenValue()),
    )

  let oref = t.test_oref(#"face", 1)

  let configAction =
    configActionUpdate(t.loanValHash, t.collateralValHash, t.rewardsMintHash)

  let configDatum1 =
    configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
  let outDatum = InlineDatum(configDatum1)

  let ownerInput =
    t.test_input(
      oref,
      t.test_output(t.test_address(test_owner), t.makeAdaValue(10), NoDatum),
    )

  let configOutput =
    t.test_output(
      t.test_script_address(t.configValHash),
      t.configValue(),
      outDatum,
    )

  let tx =
    Transaction {
      ..placeholder(),
      mint: mintValue,
      extra_signatories: [test_owner],
      inputs: [ownerInput],
      outputs: [configOutput],
    }

  let ctx = ScriptContext { purpose: Mint(t.configMintHash), transaction: tx }

  configMint(test_owner, configAction, ctx)?
}

test config_mint_datum_fail() fail {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)

  let configAction =
    configActionUpdate(t.loanValHash, t.collateralValHash, t.rewardsMintHash)

  let configDatum1 = oracleDatum(1, 1111111111, 15, 2)
  let outDatum = InlineDatum(configDatum1)

  let ownerInput =
    t.test_input(
      oref,
      t.test_output(t.test_address(test_owner), t.makeAdaValue(10), NoDatum),
    )

  let configOutput =
    t.test_output(
      t.test_script_address(t.configValHash),
      t.configValue(),
      outDatum,
    )

  let tx =
    Transaction {
      ..placeholder(),
      mint: t.configMintedValue(),
      extra_signatories: [test_owner],
      inputs: [ownerInput],
      outputs: [configOutput],
    }

  let ctx = ScriptContext { purpose: Mint(t.configMintHash), transaction: tx }

  configMint(test_owner, configAction, ctx)?
}

test config_mint_sigs_fail() fail {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)

  let configAction =
    configActionUpdate(t.loanValHash, t.collateralValHash, t.rewardsMintHash)

  let configDatum1 =
    configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
  let outDatum = InlineDatum(configDatum1)

  let ownerInput =
    t.test_input(
      oref,
      t.test_output(t.test_address(test_owner), t.makeAdaValue(10), NoDatum),
    )

  let configOutput =
    t.test_output(
      t.test_script_address(t.configValHash),
      t.configValue(),
      outDatum,
    )

  let tx =
    Transaction {
      ..placeholder(),
      mint: t.configMintedValue(),
      extra_signatories: [#"cafe"],
      inputs: [ownerInput],
      outputs: [configOutput],
    }

  let ctx = ScriptContext { purpose: Mint(t.configMintHash), transaction: tx }

  configMint(test_owner, configAction, ctx)?
}

// Config Val Tests
test config_val() {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)

  let configAction =
    configActionUpdate(t.loanValHash, t.collateralValHash, t.rewardsMintHash)

  let configDatum1 =
    configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
  let inDatum = InlineDatum(configDatum1)
  let outDatum = InlineDatum(configDatum1)

  let configInput =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(t.configValHash),
        t.configValue(),
        inDatum,
      ),
    )

  let configOutput =
    t.test_output(
      t.test_script_address(t.configValHash),
      t.configValue(),
      outDatum,
    )

  let tx =
    Transaction {
      ..placeholder(),
      extra_signatories: [test_owner],
      inputs: [configInput],
      outputs: [configOutput],
    }

  let ctx = ScriptContext { purpose: Spend(oref), transaction: tx }

  configVal(test_owner, t.configMintHash, configDatum1, configAction, ctx)?
}

test config_val_token_fail() fail {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)

  let configAction =
    configActionUpdate(t.loanValHash, t.collateralValHash, t.rewardsMintHash)

  let configDatum1 =
    configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
  let inDatum = InlineDatum(configDatum1)
  let outDatum = InlineDatum(configDatum1)

  let configInput =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(t.configValHash),
        t.makeAdaValue(10),
        // we dont check for a token input
        inDatum,
      ),
    )

  let configOutput =
    t.test_output(
      t.test_script_address(t.configValHash),
      t.makeAdaValue(10),
      // this only fails because there is no token output
      outDatum,
    )

  let tx =
    Transaction {
      ..placeholder(),
      extra_signatories: [test_owner],
      inputs: [configInput],
      outputs: [configOutput],
    }

  let ctx = ScriptContext { purpose: Spend(oref), transaction: tx }

  configVal(test_owner, t.configMintHash, configDatum1, configAction, ctx)?
}

test config_val_datum_fail() fail {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)

  let configAction =
    configActionUpdate(t.loanValHash, t.collateralValHash, t.rewardsMintHash)

  let configDatum1 =
    configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)

  let oracleDatum = oracleDatum(1, 1111111111, 1, 1)

  let inDatum = InlineDatum(configDatum1)
  let outDatum = InlineDatum(oracleDatum)

  let configInput =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(t.configValHash),
        t.configValue(),
        inDatum,
      ),
    )

  let configOutput =
    t.test_output(
      t.test_script_address(t.configValHash),
      t.configValue(),
      outDatum,
    )

  let tx =
    Transaction {
      ..placeholder(),
      extra_signatories: [test_owner],
      inputs: [configInput],
      outputs: [configOutput],
    }

  let ctx = ScriptContext { purpose: Spend(oref), transaction: tx }

  configVal(test_owner, t.configMintHash, configDatum1, configAction, ctx)?
}

test config_val_sig_fail() fail {
  let test_owner = #"face"

  let oref = t.test_oref(#"face", 1)

  let configAction =
    configActionUpdate(t.loanValHash, t.collateralValHash, t.rewardsMintHash)

  let configDatum1 =
    configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
  let inDatum = InlineDatum(configDatum1)
  let outDatum = InlineDatum(configDatum1)

  let configInput =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(t.configValHash),
        t.configValue(),
        inDatum,
      ),
    )

  let configOutput =
    t.test_output(
      t.test_script_address(t.configValHash),
      t.configValue(),
      outDatum,
    )

  let tx =
    Transaction {
      ..placeholder(),
      extra_signatories: [#"cafe"],
      inputs: [configInput],
      outputs: [configOutput],
    }

  let ctx = ScriptContext { purpose: Spend(oref), transaction: tx }

  configVal(test_owner, t.configMintHash, configDatum1, configAction, ctx)?
}

// Rewards Mint Tests
test rewards_mint() {
  let test_owner = #"face"
  let test_user = #"cafe"

  let oref = t.test_oref(#"face", 1)
  let rref = t.test_oref(#"dead", 6)

  let rewardsAction = rewardsActionMint()

  let configDatum =
    configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
  let configInDatum = InlineDatum(configDatum)

  let loanDatum = loanDatum(1000, 15, 1000, 2, 1111111190)
  let loanInDatum = InlineDatum(loanDatum)
  let outDatum = NoDatum

  let loanInput =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(t.loanValHash),
        t.loanValue(),
        loanInDatum,
      ),
    )

  let userOutput =
    t.test_output(t.test_address(test_owner), t.rewardsValue(1000), outDatum)
  let configIn =
    t.test_input(
      rref,
      t.test_output(
        t.test_script_address(t.configValHash),
        t.configValue(),
        configInDatum,
      ),
    )

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      mint: t.rewardsMintedValue(1000),
      extra_signatories: [test_owner],
      inputs: [loanInput],
      outputs: [userOutput],
    }

  let ctx = ScriptContext { purpose: Mint(t.rewardsMintHash), transaction: tx }

  rewardsMint(test_owner, t.configMintHash, t.loanMintHash, rewardsAction, ctx)?
}

// not a test but a thought for improvement:
// We should enforce an empty token name so we cant mint tokens with different ones

test rewards_mint_qty_fail() fail {
  let test_owner = #"face"
  let test_user = #"cafe"

  let oref = t.test_oref(#"face", 1)
  let rref = t.test_oref(#"dead", 6)

  let rewardsAction = rewardsActionMint()

  let configDatum =
    configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
  let configInDatum = InlineDatum(configDatum)

  let loanDatum = loanDatum(1000, 15, 1000, 2, 1111111190)
  let loanInDatum = InlineDatum(loanDatum)
  let outDatum = NoDatum

  let loanInput =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(t.loanValHash),
        t.loanValue(),
        loanInDatum,
      ),
    )

  let userOutput =
    t.test_output(t.test_address(test_owner), t.rewardsValue(100), outDatum)
  let configIn =
    t.test_input(
      rref,
      t.test_output(
        t.test_script_address(t.configValHash),
        t.configValue(),
        configInDatum,
      ),
    )

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      mint: t.rewardsMintedValue(100),
      extra_signatories: [test_owner],
      inputs: [loanInput],
      outputs: [userOutput],
    }

  let ctx = ScriptContext { purpose: Mint(t.rewardsMintHash), transaction: tx }

  rewardsMint(test_owner, t.configMintHash, t.loanMintHash, rewardsAction, ctx)?
}

test rewards_mint_loanOutput_fail() fail {
  let test_owner = #"face"
  let test_user = #"cafe"

  let oref = t.test_oref(#"face", 1)
  let rref = t.test_oref(#"dead", 6)

  let rewardsAction = rewardsActionMint()

  let configDatum =
    configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
  let configInDatum = InlineDatum(configDatum)

  let loanDatum = loanDatum(1000, 15, 1000, 2, 1111111190)
  let loanInDatum = InlineDatum(loanDatum)
  let outDatum = NoDatum

  let loanInput =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(t.loanValHash),
        t.loanValue(),
        loanInDatum,
      ),
    )

  let loanOutput =
    t.test_output(
      t.test_script_address(t.loanValHash),
      t.loanValue(),
      loanInDatum,
    )

  let userOutput =
    t.test_output(t.test_address(test_owner), t.rewardsValue(1000), outDatum)
  let configIn =
    t.test_input(
      rref,
      t.test_output(
        t.test_script_address(t.configValHash),
        t.configValue(),
        configInDatum,
      ),
    )

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      mint: t.rewardsMintedValue(1000),
      extra_signatories: [test_owner],
      inputs: [loanInput],
      outputs: [userOutput, loanOutput],
    }

  let ctx = ScriptContext { purpose: Mint(t.rewardsMintHash), transaction: tx }

  rewardsMint(test_owner, t.configMintHash, t.loanMintHash, rewardsAction, ctx)?
}

test rewards_mint_config_fail() fail {
  let test_owner = #"face"
  let test_user = #"cafe"

  let oref = t.test_oref(#"face", 1)
  let rref = t.test_oref(#"dead", 6)

  let rewardsAction = rewardsActionMint()

  let configDatum =
    configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
  let configInDatum = InlineDatum(configDatum)

  let loanDatum = loanDatum(1000, 15, 1000, 2, 1111111190)
  let loanInDatum = InlineDatum(loanDatum)
  let outDatum = NoDatum

  let loanInput =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(t.loanValHash),
        t.loanValue(),
        loanInDatum,
      ),
    )

  let userOutput =
    t.test_output(t.test_address(test_owner), t.rewardsValue(1000), outDatum)
  let configIn =
    t.test_input(
      rref,
      t.test_output(
        t.test_script_address(t.configValHash),
        t.makeAdaValue(2),
        configInDatum,
      ),
    )

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      mint: t.rewardsMintedValue(1000),
      extra_signatories: [test_owner],
      inputs: [loanInput],
      outputs: [userOutput],
    }

  let ctx = ScriptContext { purpose: Mint(t.rewardsMintHash), transaction: tx }

  rewardsMint(test_owner, t.configMintHash, t.loanMintHash, rewardsAction, ctx)?
}

test rewards_mint_noRewards_fail() fail {
  let test_owner = #"face"
  let test_user = #"cafe"

  let oref = t.test_oref(#"face", 1)
  let rref = t.test_oref(#"dead", 6)

  let rewardsAction = rewardsActionMint()

  let configDatum =
    configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
  let configInDatum = InlineDatum(configDatum)

  let loanDatum = loanDatum(1000, 15, 0, 2, 1111111190)
  let loanInDatum = InlineDatum(loanDatum)
  let outDatum = NoDatum

  let loanInput =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(t.loanValHash),
        t.loanValue(),
        loanInDatum,
      ),
    )

  let userOutput =
    t.test_output(t.test_address(test_owner), t.rewardsValue(1000), outDatum)
  let configIn =
    t.test_input(
      rref,
      t.test_output(
        t.test_script_address(t.configValHash),
        t.configValue(),
        configInDatum,
      ),
    )

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      mint: t.rewardsMintedValue(1000),
      extra_signatories: [test_owner],
      inputs: [loanInput],
      outputs: [userOutput],
    }

  let ctx = ScriptContext { purpose: Mint(t.rewardsMintHash), transaction: tx }

  rewardsMint(test_owner, t.configMintHash, t.loanMintHash, rewardsAction, ctx)?
}

test rewards_mint_fakeLoanIn_fail() fail {
  // this fails because we dont check the incoming script hash
  // if we can't remove a loan token from our control, it doesnt matter
  // but we could verify the loanIn Credential as we have the config refInput
  let test_owner = #"face"
  let test_user = #"cafe"

  let oref = t.test_oref(#"face", 1)
  let rref = t.test_oref(#"dead", 6)

  let rewardsAction = rewardsActionMint()

  let configDatum =
    configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
  let configInDatum = InlineDatum(configDatum)

  let loanDatum = loanDatum(1000, 15, 1000, 2, 1111111190)
  let loanInDatum = InlineDatum(loanDatum)
  let outDatum = NoDatum

  let loanInput =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(t.configValHash),
        t.loanValue(),
        loanInDatum,
      ),
    )

  let userOutput =
    t.test_output(t.test_address(test_owner), t.rewardsValue(1000), outDatum)
  let configIn =
    t.test_input(
      rref,
      t.test_output(
        t.test_script_address(t.configValHash),
        t.configValue(),
        configInDatum,
      ),
    )

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      mint: t.rewardsMintedValue(1000),
      extra_signatories: [test_owner],
      inputs: [loanInput],
      outputs: [userOutput],
    }

  let ctx = ScriptContext { purpose: Mint(t.rewardsMintHash), transaction: tx }

  rewardsMint(test_owner, t.configMintHash, t.loanMintHash, rewardsAction, ctx)?
}

// Loan Mint Tests
test loan_mint() {
  let test_owner = #"face"
  let test_user = #"cafe"

  let oref = t.test_oref(#"face", 1)
  let cref = t.test_oref(#"cafe", 2)
  let rref = t.test_oref(#"dead", 6)

  let mintAction = loanMintActionMint("USD", 1000, 1111111113)

  let loanMintedValue =
    value.to_minted_value(value.merge(t.loanTokenValue(), t.loanTokenValue()))

  let configDatum =
    configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
  let configInDatum = InlineDatum(configDatum)

  let loanDatum = loanDatum(1000, 15, 1000, 0, 1111111114)
  let loanOutDatum = InlineDatum(loanDatum)
  let loanOutValue = t.loanTokenValue()

  let collateralDatum = collateralDatum(2000, 12)
  let colOutDatum = InlineDatum(collateralDatum)
  let colOutValue = value.merge(t.makeAdaValue(2000), t.loanTokenValue())

  let oracleInDatum = oracleDatum(2, 11111112, 15, 2)
  let oracleOutDatum = oracleDatum(1, 11111114, 15, 2)
  let oInDatum = InlineDatum(oracleInDatum)
  let oOutDatum = InlineDatum(oracleOutDatum)

  let noDatum = NoDatum

  let userIn =
    t.test_input(
      oref,
      t.test_output(t.test_address(#"cafe"), t.makeAdaValue(2010), noDatum),
    )

  let configIn =
    t.test_input(
      cref,
      t.test_output(
        t.test_script_address(t.configValHash),
        t.configValue(),
        configInDatum,
      ),
    )

  let oracleIn =
    t.test_input(
      rref,
      t.test_output(
        t.test_script_address(t.oracleValHash),
        t.oracleValue(),
        oInDatum,
      ),
    )

  let oracleOut =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      t.oracleValue(),
      oOutDatum,
    )

  let loanOut =
    t.test_output(
      t.test_script_address(t.loanValHash),
      loanOutValue,
      loanOutDatum,
    )

  let colOut =
    t.test_output(
      t.test_script_address(t.collateralValHash),
      colOutValue,
      colOutDatum,
    )

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      mint: loanMintedValue,
      extra_signatories: [test_owner],
      inputs: [userIn, oracleIn],
      outputs: [loanOut, colOut, oracleOut],
    }

  let ctx = ScriptContext { purpose: Mint(t.loanMintHash), transaction: tx }

  loanMint(t.oracleMintHash, t.configMintHash, mintAction, ctx)?
}

// Loan Validator Tests
test loan_val() {
  let test_owner = #"face"
  let test_user = #"cafe"

  let oref = t.test_oref(#"face", 1)
  let cref = t.test_oref(#"cafe", 2)
  let rref = t.test_oref(#"dead", 6)
  let uref = t.test_oref(#"beef", 4)
  let href = t.test_oref(#"feed", 3)

  let loanAction = loanActionBalance()

  let loanMintedValue =
    value.to_minted_value(value.merge(t.loanTokenValue(), t.loanTokenValue()))

  let configDatum =
    configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
  let configInDatum = InlineDatum(configDatum)

  let loanDatum1 = loanDatum(1000, 15, 1000, 0, 1111111114)
  let loanInDatum = InlineDatum(loanDatum1)
  let loanInValue = t.loanTokenValue()

  let loanDatum2 = loanDatum(1000, 15, 1000, 0, 1111111115)
  let loanOutDatum = InlineDatum(loanDatum2)
  let loanOutValue = t.loanTokenValue()

  let collateralDatum1 = collateralDatum(2000, 12)
  let colInDatum = InlineDatum(collateralDatum1)
  let colInValue = value.merge(t.makeAdaValue(2000), t.loanTokenValue())

  let collateralDatum2 = collateralDatum(1000, 12)
  let colOutDatum = InlineDatum(collateralDatum2)
  let colOutValue = value.merge(t.makeAdaValue(1000), t.loanTokenValue())

  let oracleInDatum = oracleDatum(2, 11111112, 15, 2)
  let oracleOutDatum = oracleDatum(2, 11111114, 15, 2)
  let oInDatum = InlineDatum(oracleInDatum)
  let oOutDatum = InlineDatum(oracleOutDatum)

  let noDatum = NoDatum

  let loanIn =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(t.loanValHash),
        loanInValue,
        loanInDatum,
      ),
    )

  let colIn =
    t.test_input(
      href,
      t.test_output(
        t.test_script_address(t.collateralValHash),
        colInValue,
        colInDatum,
      ),
    )

  let userIn =
    t.test_input(
      uref,
      t.test_output(t.test_address(#"cafe"), t.makeAdaValue(2010), noDatum),
    )

  let configIn =
    t.test_input(
      cref,
      t.test_output(
        t.test_script_address(t.configValHash),
        t.configValue(),
        configInDatum,
      ),
    )

  let oracleIn =
    t.test_input(
      rref,
      t.test_output(
        t.test_script_address(t.oracleValHash),
        t.oracleValue(),
        oInDatum,
      ),
    )

  let oracleOut =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      t.oracleValue(),
      oOutDatum,
    )

  let loanOut =
    t.test_output(
      t.test_script_address(t.loanValHash),
      loanOutValue,
      loanOutDatum,
    )

  let colOut =
    t.test_output(
      t.test_script_address(t.collateralValHash),
      colOutValue,
      colOutDatum,
    )

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [userIn, oracleIn, colIn, loanIn],
      outputs: [loanOut, colOut, oracleOut],
    }

  let ctx = ScriptContext { purpose: Spend(oref), transaction: tx }

  loanVal(
    t.oracleMintHash,
    t.loanMintHash,
    t.configMintHash,
    loanDatum1,
    loanAction,
    ctx,
  )?
}

// Collateral Validator Tests
test collateral_val() {
  let test_owner = #"face"
  let test_user = #"cafe"

  let oref = t.test_oref(#"face", 1)
  let cref = t.test_oref(#"cafe", 2)
  let rref = t.test_oref(#"dead", 6)
  let uref = t.test_oref(#"beef", 4)
  let href = t.test_oref(#"feed", 3)

  let collateralAction = collateralActionBalance()

  let loanMintedValue =
    value.to_minted_value(value.merge(t.loanTokenValue(), t.loanTokenValue()))

  let configDatum =
    configDatum(t.loanValHash, t.collateralValHash, t.rewardsMintHash)
  let configInDatum = InlineDatum(configDatum)

  let loanDatum1 = loanDatum(1000, 15, 1000, 0, 1111111114)
  let loanInDatum = InlineDatum(loanDatum1)
  let loanInValue = t.loanTokenValue()

  let loanDatum2 = loanDatum(1000, 15, 1000, 0, 1111111115)
  let loanOutDatum = InlineDatum(loanDatum2)
  let loanOutValue = t.loanTokenValue()

  let collateralDatum1 = collateralDatum(2000, 12)
  let colInDatum = InlineDatum(collateralDatum1)
  let colInValue = value.merge(t.makeAdaValue(2000), t.loanTokenValue())

  let collateralDatum2 = collateralDatum(500, 12)
  // we need to make sure the amount here is 2x
  let colOutDatum = InlineDatum(collateralDatum2)
  let colOutValue = value.merge(t.makeAdaValue(1000), t.loanTokenValue())

  let oracleInDatum = oracleDatum(2, 11111112, 15, 2)
  let oracleOutDatum = oracleDatum(2, 11111114, 15, 2)
  let oInDatum = InlineDatum(oracleInDatum)
  let oOutDatum = InlineDatum(oracleOutDatum)

  let noDatum = NoDatum

  let loanIn =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(t.loanValHash),
        loanInValue,
        loanInDatum,
      ),
    )

  let colIn =
    t.test_input(
      href,
      t.test_output(
        t.test_script_address(t.collateralValHash),
        colInValue,
        colInDatum,
      ),
    )

  let userIn =
    t.test_input(
      uref,
      t.test_output(t.test_address(#"cafe"), t.makeAdaValue(2010), noDatum),
    )

  let configIn =
    t.test_input(
      cref,
      t.test_output(
        t.test_script_address(t.configValHash),
        t.configValue(),
        configInDatum,
      ),
    )

  let oracleIn =
    t.test_input(
      rref,
      t.test_output(
        t.test_script_address(t.oracleValHash),
        t.oracleValue(),
        oInDatum,
      ),
    )

  let oracleOut =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      t.oracleValue(),
      oOutDatum,
    )

  let loanOut =
    t.test_output(
      t.test_script_address(t.loanValHash),
      loanOutValue,
      loanOutDatum,
    )

  let colOut =
    t.test_output(
      t.test_script_address(t.collateralValHash),
      colOutValue,
      colOutDatum,
    )

  let tx =
    Transaction {
      ..placeholder(),
      reference_inputs: [configIn],
      extra_signatories: [test_owner],
      inputs: [userIn, oracleIn, colIn, loanIn],
      outputs: [loanOut, colOut, oracleOut],
    }

  let ctx = ScriptContext { purpose: Spend(href), transaction: tx }

  collateralVal(
    t.oracleMintHash,
    t.loanMintHash,
    t.configMintHash,
    collateralDatum1,
    collateralAction,
    ctx,
  )?
}

//              //
// Test Helpers //
//              //

fn oracleDatum(x: Int, t: PosixTime, r: Int, f: Int) -> OracleDatum {
  let datum = OracleDatum { usdAda: x, timestamp: t, rate: r, fee: f }
  datum
}

fn oracleAction(x: Int, t: PosixTime, r: Int, f: Int) -> OracleAction {
  let redeemer = OracleUpdate { usdAda: x, timestamp: t, rate: r, fee: f }
  redeemer
}

// fn oracleActionClose() -> OracleAction {
//   let redeemer = OracleClose
//   redeemer
// }

fn configDatum(l: ScriptHash, c: ScriptHash, r: ScriptHash) -> ConfigDatum {
  let datum = ConfigDatum { loanVal: l, colVal: c, rewardsVal: r }
  datum
}

fn configActionUpdate(
  l: ScriptHash,
  c: ScriptHash,
  r: ScriptHash,
) -> ConfigAction {
  let redeemer = ConUpdate { loanVal: l, colVal: c, rewardsVal: r }
  redeemer
}

// fn configActionClose() -> ConfigAction {
//   let redeemer = ConClose
//   redeemer
// }

fn loanActionBalance() -> LoanAction {
  let redeemer = SLBalance
  redeemer
}

// fn loanActionLiquidate() -> LoanAction {
//   let redeemer = SLLiquidate
//   redeemer
// }

// fn loanActionClose() -> LoanAction {
//   let redeemer = SLClose
//   redeemer
// }

fn loanMintActionMint(c: ByteArray, v: Int, t: PosixTime) -> LoanMintAction {
  let redeemer = AMint { loanCurrency: c, loanValue: v, timestamp: t }
  redeemer
}

// fn loanMintActionBurn() -> LoanMintAction {
//   let redeemer = ABurn
//   redeemer
// }

fn loanDatum(a: Int, i: Int, r: Int, t: Int, ti: PosixTime) -> LoanDatum {
  let datum =
    LoanDatum { amount: a, interest: i, rewards: r, term: t, timestamp: ti }
  datum
}

fn collateralActionBalance() -> CollateralAction {
  let redeemer = SCBalance
  redeemer
}

// fn collateralActionLiquidate() -> CollateralAction {
//   let redeemer = SCLiquidate
//   redeemer
// }

// fn collateralActionClose() -> CollateralAction {
//   let redeemer = SCClose
//   redeemer
// }

fn collateralDatum(a: Int, t: PosixTime) -> CollateralDatum {
  let datum = CollateralDatum { amount: a, timestamp: t }
  datum
}

fn rewardsActionMint() -> RewardsAction {
  let redeemer = RewardMint
  redeemer
}

// fn rewardsActionBurn() -> RewardsAction {
//   let redeemer = RewardMint
//   redeemer
// }

fn oracleMintActionMint() -> OracleMintAction {
  let redeemer = OMint
  redeemer
}
// fn oracleMintActionBurn() -> OracleMintAction {
//   let redeemer = OBurn
//   redeemer
// }
