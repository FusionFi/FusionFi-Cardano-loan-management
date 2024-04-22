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

// Currently working on colSeparated.ak - splitting data and collateral

// Add must update OracleDatum to every Validator

//            //
// Data Types //
//            //

type VerificationKeyHash =
  Hash<Blake2b_224, VerificationKey>

type ScriptHash =
  Hash<Blake2b_224, Script>

// type LoanDatum = {
//   amount: Integer
//   interest: Integer
//   term: Integer
//   status: LoanStatus
// }

// type ColDatum = {
//   amount: Integer
//   status: ColStatus
// }

type MintAction {
  AMint { loanCurrency: ByteArray, loanValue: Int, timestamp: PosixTime }
  ABurn
}

type OMintAction {
  OMint
  OBurn
}

type OracleAction {
  Update
  Close
}

type OracleDatum {
  usdAda: Int,
  timestamp: PosixTime,
}

type LoanAction {
  a: Int,
  // 1 2 3
  b: PosixTime,
  c: Int,
}

type LoanDatum {
  collateral: ByteArray,
  // asset As String e.g. "ADA"
  collateralValue: Int,
  // expected Collateral Value min
  loanCurrency: ByteArray,
  // e.g. "USD"
  loanValue: Int,
  timestamp: PosixTime,
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

//                //
// Init Loan Mint //
//                //

validator(o: PolicyId) {
  fn loanMint(r: MintAction, c: ScriptContext) -> Bool {
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
        expect Some(refIn) =
          head(
            filter(
              reference_inputs,
              fn(ref) { has(policies(ref.output.value), o) },
            ),
          )
        expect InlineDatum(datum) = refIn.output.datum
        expect rDatum: OracleDatum = datum
        let exchangeRate = rDatum.usdAda

        any(
          outputs,
          fn(output) {
            expect has(policies(output.value), policyId)
            expect InlineDatum(datum) = output.datum
            expect datum: LoanDatum = datum

            datum.loanCurrency == loanCurrency && datum.timestamp == timestamp && datum.collateralValue == datum.loanValue * 2 && lovelace_of(
              output.value,
            ) >= datum.collateralValue * exchangeRate * 1000000
          },
        )
      }

      ABurn -> True
    }
  }
}

//                 //
// Init Loan Vault //
//                 //

validator(p: PolicyId, o: PolicyId) {
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
      _ -> d.loanValue == 0
    }
  }
}

//              //
// Price Oracle //
//              //

validator(o: VerificationKeyHash, p: PolicyId) {
  fn oracleVault(d: OracleDatum, r: OracleAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Spend(ownRef) = purpose

    when r is {
      Update -> {
        let out = get_own_singleton_output(transaction, ownRef)
        expect [(_, 1)] =
          without_lovelace(out.value)
            |> tokens(p)
            |> to_list()
        expect InlineDatum(datum) = out.datum
        expect datum: OracleDatum = datum

        has(transaction.extra_signatories, o)
      }
      Close -> {
        expect Some(input) = find_input(transaction.inputs, ownRef)

        expect [(oName, 1)] =
          // get singleton name
          without_lovelace(input.output.value)
            |> tokens(p)
            |> to_list()

        expect [(oName, -1)] =
          transaction.mint
            |> value.from_minted_value()
            |> value.tokens(p)
            |> dict.to_list()

        has(transaction.extra_signatories, o)
      }
    }
  }
}

//             //
// Oracle Mint //
//             //

validator(o: VerificationKeyHash) {
  fn oracleMint(r: OMintAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Mint(policyId) = purpose

    expect [(oName, oAmt)] =
      transaction.mint
        |> from_minted_value()
        |> tokens(policyId)
        |> to_list()

    when r is {
      OMint -> list.has(transaction.extra_signatories, o) && oAmt == 1
      OBurn -> list.has(transaction.extra_signatories, o) && oAmt == -1
    }
  }
}

// Force Oracle Update //

// Every Transaction must update the oracle
// Oracle is no longer a reference input, but a regular input
// We check for an Oracle output with a matching timestamp
// Oracle validator handles the actual data change, but we do ensure the new Data is 
// being used (we might be safer using a previous exchange rate from the input)

type UMintAction {
  UMint { loanCurrency: ByteArray, loanValue: Int, timestamp: PosixTime }
  UBurn
}

//                  //
// Update Loan Mint //
//                  //

validator(o: PolicyId) {
  fn updateMint(r: UMintAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Mint(policyId) = purpose

    let Transaction { mint, inputs, outputs, .. } = transaction

    expect [(tName, tAmt)] =
      mint
        |> value.from_minted_value()
        |> value.tokens(policyId)
        |> dict.to_list()

    when r is {
      UMint { loanCurrency, loanValue, timestamp } -> {
        expect Some(oracle) =
          head(filter(outputs, fn(output) { has(policies(output.value), o) }))
        expect InlineDatum(datum) = oracle.datum
        expect rDatum: OracleDatum = datum
        let exchangeRate = rDatum.usdAda
        expect rDatum.timestamp == timestamp
        any(
          outputs,
          fn(output) {
            expect has(policies(output.value), policyId)
            expect InlineDatum(datum) = output.datum
            expect datum: LoanDatum = datum

            datum.loanCurrency == loanCurrency && datum.timestamp == timestamp && datum.collateralValue == datum.loanValue * 2 && lovelace_of(
              output.value,
            ) >= datum.collateralValue * exchangeRate * 1000000
          },
        ) && tAmt == 1
      }

      UBurn -> {
        expect Some(output) =
          find(outputs, fn(output) { has(policies(output.value), o) })
        tAmt == -1
      }
    }
  }
}

//                   //
// Update Loan Vault //
//                   //

validator(p: PolicyId, o: PolicyId) {
  fn updateVault(d: LoanDatum, r: LoanAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Spend(oref) = purpose

    let Transaction { inputs, outputs, reference_inputs, .. } = transaction

    expect Some(oracle) =
      find(outputs, fn(output) { has(policies(output.value), o) })

    expect InlineDatum(datum) = oracle.datum
    expect rDatum: OracleDatum = datum
    let exchangeRate = rDatum.usdAda
    expect rDatum.timestamp == r.b
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
      _ -> d.loanValue == 0
    }
  }
}

// Separate Collateral & LoanData //

// These contracts split collateral from Loan data with a token pair
// We will actually need a reference input to differenciate the recieve validators
// So I have added a Config ref input which has these validator hashes to check against
// credentials

type SConfigDatum {
  loanVal: ScriptHash,
  colVal: ScriptHash,
}

type SConfigAction {
  ConUpdate { loanVal: ScriptHash, colVal: ScriptHash }
  ConClose
}

type SLoanAction {
  SLBalance
  SLLiquidate
  SLClose
}

type SLoanDatum {
  amount: Int,
  interest: Int,
  term: Int,
  status: ByteArray,
}

type SColAction {
  SCBalance
  SCLiquidate
  SCClose
}

type SColDatum {
  amount: Int,
  status: ByteArray,
}

//                    //
// Separate Loan Mint //
//                    //

// Mints 2 tokens 
// sends one to loan vault with datum
// sends one to collateral vault with datum

validator(op: PolicyId, cp: PolicyId) {
  fn sLoanMint(r: MintAction, c: ScriptContext) -> Bool {
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
        expect Some(oracleIn) =
          head(
            filter(
              reference_inputs,
              fn(ref) { has(policies(ref.output.value), op) },
            ),
          )
        expect InlineDatum(datum) = oracleIn.output.datum
        expect rDatum: OracleDatum = datum
        let exchangeRate = rDatum.usdAda

        expect Some(configIn) =
          head(
            filter(
              reference_inputs,
              fn(ref) { has(policies(ref.output.value), cp) },
            ),
          )
        expect InlineDatum(datum) = configIn.output.datum
        expect cDatum: SConfigDatum = datum

        expect Some(loanOut) =
          find(
            outputs,
            fn(output) {
              output.address.payment_credential == ScriptCredential(
                cDatum.loanVal,
              ) && has(policies(output.value), policyId)
            },
          )
        expect Some(colOut) =
          find(
            outputs,
            fn(output) {
              output.address.payment_credential == ScriptCredential(
                cDatum.colVal,
              ) && has(policies(output.value), policyId)
            },
          )
        expect InlineDatum(datum) = loanOut.datum
        expect lDatum: SLoanDatum = datum
        expect InlineDatum(datum) = colOut.datum
        expect cDatum: SColDatum = datum
        lDatum.amount == loanValue && lDatum.interest == 15 && lDatum.term == 0 && lDatum.status == "Active" && cDatum.amount == loanValue * 2 && cDatum.status == "Active" && lovelace_of(
          colOut.value,
        ) >= lDatum.amount * exchangeRate * 1000000 && tAmt == 2
      }

      ABurn -> True
    }
  }
}

//                     //
// Separate Loan Vault //
//                     //

validator(op: PolicyId, lp: PolicyId) {
  fn sLoanVal(d: SLoanDatum, r: SLoanAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Spend(oref) = purpose

    let Transaction { inputs, outputs, reference_inputs, .. } = transaction

    expect Some(oracleIn) =
      find(
        reference_inputs,
        fn(input) { has(policies(input.output.value), op) },
      )
    expect InlineDatum(datum) = oracleIn.output.datum
    expect rDatum: OracleDatum = datum
    let exchangeRate = rDatum.usdAda

    expect Some(configIn) =
      find(
        reference_inputs,
        fn(input) { has(policies(input.output.value), lp) },
      )
    expect InlineDatum(datum) = configIn.output.datum
    expect cDatum: SConfigDatum = datum

    when r is {
      SLBalance -> {
        expect Some(ownIn) = find_input(inputs, oref)

        expect Some(loanToken) =
          head(flatten(without_lovelace(ownIn.output.value)))

        expect Some(colOut) =
          find(
            outputs,
            fn(output) {
              expect Some(colToken) =
                head(flatten(without_lovelace(output.value)))
              output.address.payment_credential == ScriptCredential(
                cDatum.colVal,
              ) && loanToken == colToken
            },
          )
        expect InlineDatum(datum) = colOut.datum
        expect cDatum: SColDatum = datum

        let ownOut = get_own_singleton_output(transaction, oref)
        let adaOut = lovelace_of(colOut.value) / 1000000
        let newCollateralValue = adaOut / exchangeRate
        let minCollateralValue = d.amount * exchangeRate * ( 50 / 100 )
        expect has(policies(ownOut.value), lp)
        expect InlineDatum(datum) = ownOut.datum
        expect datum: SLoanDatum = datum

        datum.amount == d.amount && datum.interest == d.interest && datum.term == d.term && datum.status == d.status && adaOut >= minCollateralValue
      }

      SLLiquidate -> {
        expect Some(ownIn) = find_input(inputs, oref)
        expect Some(loanToken) =
          head(flatten(without_lovelace(ownIn.output.value)))

        expect Some(colOut) =
          find(
            outputs,
            fn(output) {
              expect Some(colToken) =
                head(flatten(without_lovelace(output.value)))
              output.address.payment_credential == ScriptCredential(
                cDatum.colVal,
              ) && loanToken == colToken
            },
          )
        expect InlineDatum(datum) = colOut.datum
        expect cDatum: SColDatum = datum

        let ownOut = get_own_singleton_output(transaction, oref)
        let adaOut = lovelace_of(colOut.value) / 1000000
        let newCollateralValue = adaOut / exchangeRate
        expect has(policies(ownOut.value), lp)
        expect InlineDatum(datum) = ownOut.datum
        expect datum: SLoanDatum = datum
        let minCollateralValue = datum.amount * exchangeRate * ( 85 / 100 )

        datum.amount == d.amount && datum.interest == d.interest && datum.term == d.term && datum.status == d.status && adaOut >= minCollateralValue
      }
      // close
      SLClose -> d.amount == 0
    }
  }
}

//                           //
// Separate Collateral Vault //
//                           //

validator(op: PolicyId, lp: PolicyId) {
  fn cVal(d: SColDatum, r: SColAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Spend(oref) = purpose

    let Transaction { inputs, outputs, reference_inputs, .. } = transaction

    expect Some(oracleIn) =
      find(
        reference_inputs,
        fn(input) { has(policies(input.output.value), op) },
      )
    expect InlineDatum(datum) = oracleIn.output.datum
    expect rDatum: OracleDatum = datum
    let exchangeRate = rDatum.usdAda

    expect Some(configIn) =
      find(
        reference_inputs,
        fn(input) { has(policies(input.output.value), lp) },
      )
    expect InlineDatum(datum) = configIn.output.datum
    expect cDatum: SConfigDatum = datum

    when r is {
      SCBalance -> {
        expect Some(ownIn) = find_input(inputs, oref)

        expect Some(collateralToken) =
          head(flatten(without_lovelace(ownIn.output.value)))

        expect Some(loanOut) =
          find(
            outputs,
            fn(output) {
              expect Some(loanToken) =
                head(flatten(without_lovelace(output.value)))
              output.address.payment_credential == ScriptCredential(
                cDatum.loanVal,
              ) && loanToken == collateralToken
            },
          )
        expect InlineDatum(datum) = loanOut.datum
        expect lDatum: SLoanDatum = datum

        let ownOut = get_own_singleton_output(transaction, oref)
        expect InlineDatum(datum) = ownOut.datum
        expect outDatum: SColDatum = datum

        lovelace_of(ownOut.value) >= lDatum.amount * exchangeRate * ( 50 / 100 ) * 1000000 && outDatum.amount == lovelace_of(
          ownOut.value,
        ) / exchangeRate / 1000000 && has(
          flatten(ownOut.value),
          collateralToken,
        )
      }
      // && outDatum.timestamp == timestamp
      SCLiquidate -> {
        expect Some(ownIn) = find_input(inputs, oref)

        expect Some(collateralToken) =
          head(flatten(without_lovelace(ownIn.output.value)))

        expect Some(loanOut) =
          find(
            outputs,
            fn(output) {
              expect Some(loanToken) =
                head(flatten(without_lovelace(output.value)))
              output.address.payment_credential == ScriptCredential(
                cDatum.loanVal,
              ) && loanToken == collateralToken
            },
          )
        expect InlineDatum(datum) = loanOut.datum
        expect lDatum: SLoanDatum = datum

        let ownOut = get_own_singleton_output(transaction, oref)
        expect InlineDatum(datum) = ownOut.datum
        expect outDatum: SColDatum = datum

        lovelace_of(ownOut.value) >= lDatum.amount * exchangeRate * ( 50 / 100 ) * 1000000 && outDatum.amount == lovelace_of(
          ownOut.value,
        ) / exchangeRate / 1000000 && has(
          flatten(ownOut.value),
          collateralToken,
        )
      }

      // && outDatum.timestamp == timestamp
      SCClose -> True
    }
  }
}

//                  //
// Config Validator //
//                  //

validator(o: VerificationKeyHash, cp: PolicyId) {
  fn configValidator(
    d: SConfigDatum,
    r: SConfigAction,
    c: ScriptContext,
  ) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Spend(oref) = purpose

    let Transaction { inputs, outputs, extra_signatories, .. } = transaction

    when r is {
      ConUpdate { loanVal, colVal } -> {
        let ownOut = get_own_singleton_output(transaction, oref)
        expect InlineDatum(datum) = ownOut.datum
        expect outDatum: SConfigDatum = datum

        has(extra_signatories, o) && has(policies(ownOut.value), cp) && outDatum.loanVal == loanVal && outDatum.colVal == colVal
      }

      ConClose -> has(extra_signatories, o)
    }
  }
}

//                       //
// Config Minting Policy //
//                       //

validator(o: VerificationKeyHash) {
  fn configMint(r: SConfigAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Mint(policyId) = purpose

    let Transaction { outputs, extra_signatories, mint, .. } = transaction

    expect [(tName, tAmt)] =
      mint
        |> value.from_minted_value()
        |> value.tokens(policyId)
        |> dict.to_list()

    when r is {
      ConUpdate { loanVal, colVal } -> {
        expect Some(ownOut) =
          find(outputs, fn(output) { has(policies(output.value), policyId) })
        expect InlineDatum(datum) = ownOut.datum
        expect outDatum: SConfigDatum = datum

        outDatum.loanVal == loanVal && outDatum.colVal == colVal && has(
          extra_signatories,
          o,
        ) && tAmt == 1
      }

      ConClose -> has(extra_signatories, o) && tAmt == -1
    }
  }
}

// Fees And Rates //

// We want to be able to add fees and rates to the loans
// this will allow us to earn revenue at every transaction
// We will start with fixed rates and fees

// Tx -> every Tx costs 2ADA
// APR 15% -> charged to date on every payment
// liquidation costs 10% -> liquidator earns up to 5%?

// I have actually accounted for variable rates here in theses example functions,
// To apply variable rates according to asset, we will add these values to the oracle
// and enable us to adjust these values as necessary

//                 //
// Rates Loan Mint //
//                 //

validator(o: PolicyId, t: PaymentCredential) {
  fn ratesLoanMint(r: MintAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Mint(policyId) = purpose

    let Transaction { mint, outputs, reference_inputs, .. } = transaction

    expect [(tName, tAmt)] =
      mint
        |> value.from_minted_value()
        |> value.tokens(policyId)
        |> dict.to_list()
    let f = 2

    when r is {
      AMint { loanCurrency, loanValue, timestamp } -> {
        expect Some(refIn) =
          head(
            filter(
              reference_inputs,
              fn(ref) { has(policies(ref.output.value), o) },
            ),
          )
        expect InlineDatum(datum) = refIn.output.datum
        expect rDatum: VarODatum = datum
        let exchangeRate = rDatum.usdAda

        any(
          outputs,
          fn(output) {
            expect has(policies(output.value), policyId)
            expect InlineDatum(datum) = output.datum
            expect datum: LoanDatum = datum

            datum.loanCurrency == loanCurrency && datum.timestamp == timestamp && datum.collateralValue == datum.loanValue * 2 && lovelace_of(
              output.value,
            ) >= datum.collateralValue * exchangeRate * 1000000
          },
        ) && // Fee
        any(
          transaction.outputs,
          fn(output) {
            output.address.payment_credential == t && lovelace_of(output.value) >= f * 1000000
          },
        )
      }

      ABurn -> True
    }
  }
}

// fn fixed_fee(tx: Transaction, f: Int, o: VerificationKeyHash) -> Bool {
//   any(
//     transaction.outputs,
//     fn(output) {
//       output.address.payment_credential == o && lovelace_of(output.value) >= f * 1000000
//     },
//   )
// }

// Helper Function //

fn calculate_rate(last: PosixTime, new: PosixTime, rate: Int) -> Int {
  let day = 86400
  let diff = new - last
  let daysToCharge = diff / day
  let dailyRate = rate / 365
  let apr = dailyRate * rate

  apr
}

//                  //
// Rates Loan Vault //
//                  //

validator(p: PolicyId, o: PolicyId, t: PaymentCredential) {
  fn ratesLoanVault(d: LoanDatum, r: LoanAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Spend(oref) = purpose

    let Transaction { inputs, outputs, reference_inputs, .. } = transaction

    expect Some(refIn) =
      find(reference_inputs, fn(input) { has(policies(input.output.value), o) })

    expect InlineDatum(datum) = refIn.output.datum
    expect rDatum: VarODatum = datum
    let exchangeRate = rDatum.usdAda
    let rate = rDatum.rate

    expect Some(ownInput) = find_input(transaction.inputs, oref)
    let loanInput = lovelace_of(ownInput.output.value)

    let f = 2

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

        expect
          any(
            outputs,
            fn(output) {
              let ratePayment =
                loanInput * calculate_rate(d.timestamp, r.b, rate)
              let fee = f * 1000000
              output.address.payment_credential == t && lovelace_of(
                output.value,
              ) >= ratePayment + fee
            },
          )
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

        expect
          any(
            outputs,
            fn(output) {
              let minCollateral = datum.loanValue * exchangeRate * 1000000
              let ratePayment =
                loanInput * calculate_rate(d.timestamp, r.b, rate)
              let fee = f * 1000000
              output.address.payment_credential == t && lovelace_of(
                output.value,
              ) >= minCollateral + ratePayment + fee
            },
          )
        datum.collateral == d.collateral && datum.collateralValue == newCollateralValue && datum.loanCurrency == d.loanCurrency && datum.loanValue == d.loanValue - r.c && datum.timestamp == r.b && adaOut >= minCollateralValue
      }
      // close
      _ -> {
        expect
          any(
            outputs,
            fn(output) {
              let ratePayment =
                loanInput * calculate_rate(d.timestamp, r.b, rate)
              let fee = f * 1000000
              output.address.payment_credential == t && lovelace_of(
                output.value,
              ) >= ratePayment + fee
            },
          )
        d.loanValue == 0
      }
    }
  }
}

// fn balance_loan(tx: Transaction, f: Int, r: Int, o: VerificationKeyHash) -> Bool {
//   any(
//     tx.outputs,
//     fn(output) {
//       let ratePayment =
//         lovelace_of(loanInput) * calculate_rate(
//           inDatum.timestamp,
//           redeemer.timestamp,
//           r,
//         )
//       let fee = f * 1000000
//       output.address.payment_credential == o && lovelace_of(output.value) >= ratePayment + fee
//     },
//   )
// }

// fn liquidate_loan(
//   tx: Transaction,
//   f: Int,
//   r: Int,
//   o: VerificationKeyHash,
// ) -> Bool {
//   any(
//     tx.outputs,
//     fn(output) {
//       let minCollateral = lovelace_of(lDatum.loanValue) * exchangeRate * 1000000
//       let ratePayment =
//         loanInput * calculate_rate(inDatum.timestamp, redeemer.timestamp, r)
//       let fee = f * 1000000
//       output.address.payment_credential == o && lovelace_of(output.value) >= minCollateral + ratePayment + fee
//     },
//   )
// }

// fn close_loan(tx: Transaction, f: Int, r: Int, o: VerificationKeyHash) -> Bool {
//   any(
//     tx.outputs,
//     fn(output) {
//       let ratePayment =
//         loanInput * calculate_rate(inDatum.timestamp, redeemer.timestamp, r)
//       let fee = f * 1000000
//       output.address.payment_credential == o && lovelace_of(output.value) >= ratePayment + fee
//     },
//   )
// }

//                       //
// Variable Oracle Datum //
//                       //

type VarODatum {
  usdAda: Int,
  timestamp: PosixTime,
  rate: Int,
  fee: Int,
}

//                 //
// Variable Oracle //
//                 //

validator(o: VerificationKeyHash, p: PolicyId) {
  fn varOracleVault(d: VarODatum, r: OracleAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Spend(ownRef) = purpose

    when r is {
      Update -> {
        let out = get_own_singleton_output(transaction, ownRef)
        expect [(_, 1)] =
          without_lovelace(out.value)
            |> tokens(p)
            |> to_list()
        expect InlineDatum(datum) = out.datum
        expect datum: VarODatum = datum

        has(transaction.extra_signatories, o)
      }
      Close -> {
        expect Some(input) = find_input(transaction.inputs, ownRef)

        expect [(oName, 1)] =
          // get singleton name
          without_lovelace(input.output.value)
            |> tokens(p)
            |> to_list()

        expect [(oName, -1)] =
          transaction.mint
            |> value.from_minted_value()
            |> value.tokens(p)
            |> dict.to_list()

        has(transaction.extra_signatories, o)
      }
    }
  }
}

//                    //
// Rewards Mechanisms //
//                    //

// We will have a rewards minting policy to allow us to mint on demand
// at the point of closing a loan.
// This info will be added to the Loan Datum to be updated every transaction
// If a loan is liquidated then no rewards tokens will be minted

//                      //
// Rewards Token Policy //
//                      //

type RConfigDatum {
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

type RewardsAction {
  RewardMint
  RewardBurn
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
        fn(input) { has(policies(input.output.value), cp) },
      )
    expect InlineDatum(datum) = refIn.output.datum
    expect cDatum: RConfigDatum = datum

    expect [(tName, tAmt)] =
      mint
        |> value.from_minted_value()
        |> value.tokens(policyId)
        |> dict.to_list()

    when r is {
      RewardMint -> {
        expect Some(loanIn) =
          find(
            transaction.inputs,
            fn(input) { has(policies(input.output.value), cp) },
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

//                    //
// Rewards Loan Vault //
//                    //

validator(p: PolicyId, o: PolicyId, cp: PolicyId) {
  fn rewardsLoanVault(d: LoanDatum, r: LoanAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Spend(oref) = purpose

    let Transaction { inputs, outputs, reference_inputs, extra_signatories, .. } =
      transaction

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
        expect cDatum: RConfigDatum = datum
        let rewardsHash = cDatum.rewardsVal

        has(extra_signatories, rewardsHash) && d.loanValue == 0
      }
    }
  }
}
