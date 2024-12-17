use aiken/crypto.{ScriptHash}
use cardano/assets
use cardano/transaction.{InlineDatum, Input, NoDatum, Output, OutputReference}
use ccfl/typesv3.{
  CollateralDatum, InterestDatum, LoanDatum, MerkelConfigDatum, OracleDatum,
  SupplyDatum, Withdraw, WithdrawAction,
}
use tests/scripts as s
use tests/tools as t

pub fn oref(hash: ByteArray, index: Int) -> OutputReference {
  t.test_oref(hash, index)
}

pub fn withdrawal(script: ScriptHash) {
  let withdraw0 = [Pair(t.create_script_credential(script), 0)]
  withdraw0
}

pub fn withdrawAction(i: Int) -> WithdrawAction {
  let action = Withdraw { a: [i] }
  action
}

pub fn configDatum(
  loanVal: ScriptHash,
  colVal: ScriptHash,
  oracleVal: ScriptHash,
  interestVal: ScriptHash,
  supplyVal: ScriptHash,
  collateralRedeemers: List<ScriptHash>,
  supplyRedeemers: List<ScriptHash>,
) -> MerkelConfigDatum {
  MerkelConfigDatum(
    loanVal,
    colVal,
    oracleVal,
    interestVal,
    supplyVal,
    collateralRedeemers,
    supplyRedeemers,
  )
}

pub fn configDatumIn() -> MerkelConfigDatum {
  MerkelConfigDatum(
    s.loan,
    s.collateral,
    s.oracle,
    s.interest,
    s.supply,
    [s.balance, s.liquidate, s.repay, s.close],
    [s.supply, s.lend, s.withdraw, s.close],
  )
}

pub fn loanDatum(
  amount: Int,
  rewards: Int,
  term: Int,
  timestamp: Int,
  oracle: ByteArray,
  pkh: ByteArray,
) -> LoanDatum {
  LoanDatum(amount, rewards, term, timestamp, oracle, pkh)
}

pub fn loanDatumIn(amount: Int) -> LoanDatum {
  LoanDatum(amount, amount, 31556926, 1111111111111, #"beef", #"cafe")
}

pub fn loanTimestampDatum(amount: Int, timestamp: Int) -> LoanDatum {
  LoanDatum(amount, amount, 31556926, timestamp, #"beef", #"cafe")
}

pub fn loanDatumOut(amount: Int) -> LoanDatum {
  LoanDatum(amount, amount, 31556926, 1111111111112, #"beef", #"cafe")
}

pub fn collateralDatum(amount: Int, timestamp: Int) -> CollateralDatum {
  CollateralDatum(amount, timestamp)
}

pub fn collateralDatumIn(amount) -> CollateralDatum {
  CollateralDatum(amount, 1111111111111)
}

pub fn oracleDatum(
  exchange: Int,
  timestamp: Int,
  currency: ByteArray,
  supply: Int,
  borrowed: Int,
) -> OracleDatum {
  OracleDatum(exchange, timestamp, currency, supply, borrowed)
}

pub fn oracleDatumIn(ratio: Int) -> OracleDatum {
  OracleDatum(ratio, 1111111111111, "USD", 1000000, 200000)
}

pub fn oracleTimestampDatum(ratio: Int, timestamp: Int) -> OracleDatum {
  OracleDatum(ratio, timestamp, "USD", 1000000, 200000)
}

pub fn oracleDatumOut(ratio: Int) -> OracleDatum {
  OracleDatum(ratio, 1111111111112, "USD", 1000000, 200000)
}

pub fn interestDatum(
  base: Int,
  optimal: Int,
  slope1: Int,
  slope2: Int,
  term: Int,
) -> InterestDatum {
  InterestDatum(base, optimal, slope1, slope2, term)
}

pub fn interestDatumIn() -> InterestDatum {
  let base = 55
  let optimal = 70
  let slope1 = 40
  let slope2 = 300
  let term = 31556926

  InterestDatum(base, optimal, slope1, slope2, term)
}

pub fn supplyDatum(policy, asset) -> SupplyDatum {
  SupplyDatum(policy, asset)
}

pub fn supplyDatumIn() -> SupplyDatum {
  SupplyDatum("USD", "")
}

pub fn configInput() -> Input {
  let configIn =
    t.test_input(
      oref(#"cece", 1),
      t.test_output(
        t.test_script_address(s.config),
        assets.from_asset(s.config, #"beef", 1),
        InlineDatum(configDatumIn()),
      ),
    )
  configIn
}

pub fn oracleInput(ratio: Int) -> Input {
  let oracleIn =
    t.test_input(
      oref(#"dead", 6),
      t.test_output(
        t.test_script_address(s.oracle),
        assets.from_asset(s.oracle, #"beef", 1),
        InlineDatum(oracleDatumIn(ratio)),
      ),
    )
  oracleIn
}

pub fn oracleTimestampInput(ratio: Int, timestamp: Int) -> Input {
  let oracleIn =
    t.test_input(
      oref(#"dead", 6),
      t.test_output(
        t.test_script_address(s.oracle),
        assets.from_asset(s.oracle, #"beef", 1),
        InlineDatum(oracleTimestampDatum(ratio, timestamp)),
      ),
    )
  oracleIn
}

pub fn interestInput() -> Input {
  let base = 55
  let optimal = 70
  let slope1 = 40
  let slope2 = 300
  let term = 31556926

  let interestIn =
    t.test_input(
      oref(#"deaf", 8),
      t.test_output(
        t.test_script_address(s.interest),
        assets.from_asset(s.oracle, #"beef", 1),
        InlineDatum(interestDatum(base, optimal, slope1, slope2, term)),
      ),
    )

  interestIn
}

pub fn loanInput(n: Int, amount: Int) -> Input {
  let loanIn =
    t.test_input(
      oref(#"face", n),
      t.test_output(
        t.test_script_address(s.loan),
        assets.from_asset(s.loan, #"cafe", 1),
        InlineDatum(loanDatumIn(amount)),
      ),
    )
  loanIn
}

pub fn loanTimestampInput(n: Int, amount: Int, timestamp: Int) -> Input {
  let loanIn =
    t.test_input(
      oref(#"face", n),
      t.test_output(
        t.test_script_address(s.loan),
        assets.from_asset(s.loan, #"cafe", 1),
        InlineDatum(loanTimestampDatum(amount, timestamp)),
      ),
    )
  loanIn
}

pub fn collateralInput(n: Int, amount: Int, value: Int) -> Input {
  let colIn =
    t.test_input(
      oref(#"cafe", n),
      t.test_output(
        t.test_script_address(s.collateral),
        assets.merge(
          t.makeAdaValue(value),
          assets.from_asset(s.loan, #"cafe", 1),
        ),
        InlineDatum(collateralDatumIn(amount)),
      ),
    )
  colIn
}

pub fn supplyInput() -> Input {
  let supplyIn =
    t.test_input(
      oref(#"cafe", 3),
      t.test_output(
        t.test_script_address(s.supply),
        assets.merge(t.makeAdaValue(2), assets.from_asset(s.oracle, #"beef", 1)),
        InlineDatum(supplyDatumIn()),
      ),
    )
  supplyIn
}

pub fn userAdaInput(n: Int) -> Input {
  let user =
    t.test_input(
      oref(#"9999", 3),
      t.test_output(t.test_address(#"cafe"), t.makeAdaValue(2), NoDatum),
    )
  user
}

pub fn userAdaOutput(n: Int) -> Output {
  let user = t.test_output(t.test_address(#"cafe"), t.makeAdaValue(2), NoDatum)
  user
}

pub fn oracleOutput(ratio: Int) -> Output {
  t.test_output(
    t.test_script_address(s.oracle),
    assets.from_asset(s.oracle, #"beef", 1),
    InlineDatum(oracleDatumOut(ratio)),
  )
}

pub fn oracleTimestampOutput(ratio: Int, timestamp: Int) -> Output {
  t.test_output(
    t.test_script_address(s.oracle),
    assets.from_asset(s.oracle, #"beef", 1),
    InlineDatum(oracleTimestampDatum(ratio, timestamp)),
  )
}

pub fn loanOutput(amount: Int) -> Output {
  t.test_output(
    t.test_script_address(s.loan),
    assets.from_asset(s.loan, #"cafe", 1),
    InlineDatum(loanDatumIn(amount)),
  )
}

pub fn loanTimestampOutput(amount: Int, timestamp: Int) -> Output {
  t.test_output(
    t.test_script_address(s.loan),
    assets.from_asset(s.loan, #"cafe", 1),
    InlineDatum(loanTimestampDatum(amount, timestamp)),
  )
}

pub fn collateralOutput(amount: Int, value: Int) -> Output {
  t.test_output(
    t.test_script_address(s.collateral),
    assets.merge(t.makeAdaValue(value), assets.from_asset(s.loan, #"cafe", 1)),
    InlineDatum(collateralDatumIn(amount)),
  )
}
