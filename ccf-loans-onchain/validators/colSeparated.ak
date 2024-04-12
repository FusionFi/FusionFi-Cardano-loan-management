type LoanDatum = {
  amount: Integer
  interest: Integer
  term: Integer
  status: LoanStatus
}

type ColDatum = {
  amount: Integer
  status: ColStatus
}

validator(o: PolicyId, l: PolicyId) {
  fn lVal(d: LoanDatum, r: LoanAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Spend(oref) = transaction

    when r is {
      Update -> True
      Liquidate -> True
      Close -> True
    }
  }
}

validator(o: PolicyId, l: PolicyId) {
  fn cVal(d: ColDatum, r: ColAction, c: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = c
    expect Spend(oref) = transaction

    when r is {
      Balance -> True
      Liquidate -> True
      Close -> True
    }
  }
}