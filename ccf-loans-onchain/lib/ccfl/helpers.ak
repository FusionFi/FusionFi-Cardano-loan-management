use aiken/collection/list
use aiken/crypto.{ScriptHash}
use cardano/address.{Address, Script}
use cardano/assets.{PolicyId, Value}
use cardano/transaction.{
  InlineDatum, Input, Output, OutputReference, Transaction, find_input,
  find_script_outputs,
}
use ccfl/types.{
  CollateralDatum, InterestDatum, LoanDatum, MerkelConfigDatum, OracleDatum,
}

//         //
// Helpers //
//         //

// List<Pair<Value, LoanDatum>, Pair<Value, CollateralDatum>>
pub fn get_loan_col_in(
  ins: List<Input>,
  loanValue: Value,
  loanHash: ScriptHash,
  colHash: ScriptHash,
) {
  expect Some(loanIn) =
    list.find(
      ins,
      fn(in) {
        in.output.address.payment_credential == Script(loanHash) && assets.without_lovelace(
          in.output.value,
        ) == loanValue
      },
    )
  expect InlineDatum(datum) = loanIn.output.datum
  expect lin: LoanDatum = datum
  expect Some(colIn) =
    list.find(
      ins,
      fn(in) {
        in.output.address.payment_credential == Script(colHash) && assets.without_lovelace(
          in.output.value,
        ) == loanValue
      },
    )
  expect InlineDatum(datum) = colIn.output.datum
  expect cin: CollateralDatum = datum

  (loanIn.output.value, lin, colIn.output.value, cin)
}

pub fn get_loan_col_in_datum(
  ins: List<Input>,
  loanValue: Value,
  loanHash: ScriptHash,
  colHash: ScriptHash,
) -> Pair<LoanDatum, CollateralDatum> {
  expect Some(loanIn) =
    list.find(
      ins,
      fn(in) {
        in.output.address.payment_credential == Script(loanHash) && assets.without_lovelace(
          in.output.value,
        ) == loanValue
      },
    )
  expect InlineDatum(datum) = loanIn.output.datum
  expect lin: LoanDatum = datum
  expect Some(colIn) =
    list.find(
      ins,
      fn(in) {
        in.output.address.payment_credential == Script(colHash) && assets.without_lovelace(
          in.output.value,
        ) == loanValue
      },
    )
  expect InlineDatum(datum) = colIn.output.datum
  expect cin: CollateralDatum = datum

  Pair(lin, cin)
}

pub fn get_config_datum(ref: List<Input>, policy: PolicyId) -> MerkelConfigDatum {
  expect Some(configIn) =
    list.find(
      ref,
      fn(input) { list.has(assets.policies(input.output.value), policy) },
    )

  expect InlineDatum(datum) = configIn.output.datum
  expect cDatum: MerkelConfigDatum = datum

  cDatum
}

pub fn get_interest_datum(
  ref: List<Input>,
  policy: PolicyId,
  script: ScriptHash,
) -> InterestDatum {
  expect Some(interestRef) =
    list.find(
      ref,
      fn(input) {
        list.has(assets.policies(input.output.value), policy) && input.output.address.payment_credential == Script(
          script,
        )
      },
    )

  expect InlineDatum(datum) = interestRef.output.datum
  expect iDatum: InterestDatum = datum

  iDatum
}

pub fn get_oracle_datum(
  outs: List<Output>,
  policy: PolicyId,
  script: ScriptHash,
) -> OracleDatum {
  expect Some(oracleOut) =
    list.find(
      outs,
      fn(output) {
        list.has(assets.policies(output.value), policy) && output.address.payment_credential == Script(
          script,
        )
      },
    )

  expect InlineDatum(datum) = oracleOut.datum
  expect rDatum: OracleDatum = datum

  rDatum
}

pub fn get_oracle_datum_value(
  outs: List<Output>,
  policy: PolicyId,
  script: ScriptHash,
) -> Pair<Value, OracleDatum> {
  expect Some(oracleOut) =
    list.find(
      outs,
      fn(output) {
        output.address.payment_credential == Script(script) && list.has(
          assets.policies(output.value),
          policy,
        )
      },
    )

  expect InlineDatum(datum) = oracleOut.datum
  expect rDatum: OracleDatum = datum

  Pair(assets.without_lovelace(oracleOut.value), rDatum)
}

pub fn oneIO_List(
  oref: OutputReference,
  inputs: List<Input>,
  outputs: List<Output>,
) -> Pair<Input, Output> {
  expect Some(in) = inputs |> find_input(oref)

  let cred = in.output.address.payment_credential

  let ownInputs =
    list.filter(
      inputs,
      fn(input) {
        input.output.address.payment_credential == cred && input.output.address.stake_credential == None
      },
    )
  let ownOutputs =
    list.filter(
      outputs,
      fn(output) {
        output.address.payment_credential == cred && output.address.stake_credential == None
      },
    )

  expect list.length(ownInputs) == 1
  expect list.length(ownOutputs) == 1

  expect Some(i) = list.head(ownInputs)
  expect Some(o) = list.head(ownOutputs)

  Pair(i, o)
}

// Don't use this function, it was an optimisation test for the above
// used to benchmark mem & cpu efficiencies for the optim of other functions
pub fn oneIO_Tx(oref: OutputReference, tx: Transaction) -> Pair<Input, Output> {
  expect Some(in) = tx.inputs |> find_input(oref)

  let cred = in.output.address.payment_credential

  let ownInputs =
    list.filter(
      tx.inputs,
      fn(input) {
        input.output.address.payment_credential == cred && input.output.address.stake_credential == None
      },
    )
  let ownOutputs =
    list.filter(
      tx.outputs,
      fn(output) {
        output.address.payment_credential == cred && output.address.stake_credential == None
      },
    )

  expect list.length(ownInputs) == 1
  expect list.length(ownOutputs) == 1

  expect Some(i) = list.head(ownInputs)
  expect Some(o) = list.head(ownOutputs)

  Pair(i, o)
}

pub fn has_singleton_input(tx: Transaction, oref: OutputReference) -> Bool {
  expect Some(input) =
    tx.inputs
      |> find_input(oref)

  expect Script(script_hash) = input.output.address.payment_credential

  list.length(
    list.filter(
      tx.inputs,
      fn(input) {
        input.output.address.payment_credential == Script(script_hash)
      },
    ),
  ) == 1
}

pub fn get_own_singleton_output(
  tx: Transaction,
  oref: OutputReference,
) -> Output {
  expect Some(input) =
    tx.inputs
      |> find_input(oref)

  expect Script(script_hash) = input.output.address.payment_credential
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

pub fn withBurn(
  checkBurn: fn(Output) -> Bool,
  _loanVal: ScriptHash,
  redeemer: List<Int>,
  tx: Transaction,
) -> Bool {
  let Transaction { inputs, .. } = tx

  let txList =
    list.map(
      redeemer,
      fn(index) {
        let in = index
        expect Some(input) = list.at(inputs, in)
        input
      },
    )

  list.all(txList, fn(input) { checkBurn(input.output) })
}

pub fn merkelTx(
  validate: fn(Output, Output) -> Bool,
  redeemer: List<Int>,
  outputs: List<Output>,
) -> Bool {
  let txList =
    list.map(
      redeemer,
      fn(index) {
        let l = index
        expect Some(col) = list.at(outputs, l)
        expect Some(loan) =
          list.find(
            outputs,
            fn(output) {
              assets.without_lovelace(output.value) == assets.without_lovelace(
                col.value,
              ) && output.address.payment_credential != col.address.payment_credential
            },
          )
        (col, loan)
      },
    )

  list.all(
    txList,
    fn(pair) {
      let (col, loan) = pair
      validate(col, loan)
    },
  )
}

pub fn merkelBurn(
  validate: fn(Output, Output) -> Bool,
  redeemer: List<Int>,
  inputs: List<Input>,
) -> Bool {
  let txList =
    list.map(
      redeemer,
      fn(index) {
        let l = index
        expect Some(loan) = list.at(inputs, l)
        expect Some(col) =
          list.find(
            inputs,
            fn(input) {
              assets.without_lovelace(input.output.value) == assets.without_lovelace(
                loan.output.value,
              ) && input.output.address.payment_credential != loan.output.address.payment_credential
            },
          )
        (loan.output, col.output)
      },
    )

  list.all(
    txList,
    fn(pair) {
      let (loan, col) = pair
      validate(loan, col)
    },
  )
}

pub fn merkelYield(
  outputs: List<Output>,
  redeemer: List<Int>,
  validate: fn(Output) -> Bool,
) -> Bool {
  let filtered =
    list.map(
      redeemer,
      fn(index) {
        expect Some(out) = list.at(outputs, index)
        out
      },
    )

  list.all(filtered, fn(output) { validate(output) })
}
