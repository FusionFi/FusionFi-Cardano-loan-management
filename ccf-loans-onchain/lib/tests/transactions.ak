use aiken/crypto.{ScriptHash}
use cardano/assets.{AssetName, Value}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{
  Datum, InlineDatum, Input, NoDatum, Output, OutputReference, Transaction,
}
use ccfl/types.{
  AMint, CollateralAction, CollateralDatum, ConUpdate, ConfigAction, ConfigDatum,
  InterestAction, InterestDatum, InterestUpdate, LoanAction, LoanDatum,
  LoanMintAction, MConUpdate, MerkelCollateralAction, MerkelConfigAction,
  MerkelConfigDatum, MerkelLoanAction, OMint, OracleAction, OracleDatum,
  OracleMintAction, OracleUpdate, RewardMint, RewardsAction, SCBalance, SCClose,
  SCLiquidate, SLBalance, SLClose, SLLiquidate, Withdraw, WithdrawRedeemer,
}
use tests/tools as t

//                             //
// Transaction Testing Helpers //
//                             //

pub fn interestDatum(
  base: Int,
  optimal: Int,
  slope1: Int,
  slope2: Int,
  term: Int,
) -> InterestDatum {
  let iDatum = InterestDatum { base, optimal, slope1, slope2, term }

  iDatum
}

pub fn interestAction(base, optimal, slope1, slope2, term) -> InterestAction {
  let redeemer = InterestUpdate { base, optimal, slope1, slope2, term }

  redeemer
}

pub fn oref(hash: ByteArray, index: Int) -> OutputReference {
  t.test_oref(hash, index)
}

pub fn withdrawRedeemer(a: List<Int>) -> WithdrawRedeemer {
  let redeemer = Withdraw { a }
  redeemer
}

pub fn merkelLoanAction(i: Int) -> MerkelLoanAction {
  let redeemer = MerkelLoanAction { i }
  redeemer
}

pub fn merkelCollateralAction(i: Int) -> MerkelCollateralAction {
  let redeemer = MerkelCollateralAction { i }
  redeemer
}

pub fn mConfigDatum(
  l: ScriptHash,
  c: ScriptHash,
  r: ScriptHash,
  o: ScriptHash,
  i: ScriptHash,
  y: ScriptHash,
  cR: List<ScriptHash>,
) -> MerkelConfigDatum {
  let datum =
    MerkelConfigDatum {
      loanVal: l,
      colVal: c,
      rewardsVal: r,
      oracleVal: o,
      interestVal: i,
      yield: y,
      collateralRedeemers: cR,
    }
  datum
}

pub fn mConUpdate(
  loan: ScriptHash,
  collateral: ScriptHash,
  rewards: ScriptHash,
  oracle: ScriptHash,
  interestVal: ScriptHash,
  collateralRedeemers: List<ScriptHash>,
) -> MerkelConfigAction {
  let redeemer =
    MConUpdate {
      loanVal: loan,
      colVal: collateral,
      rewardsVal: rewards,
      oracleVal: oracle,
      interestVal,
      collateralRedeemers,
    }
  redeemer
}

pub fn oracleDatum(x: Int, t: Int, s: Int, b: Int, c: ByteArray) -> OracleDatum {
  let datum =
    OracleDatum {
      exchange: x,
      timestamp: t,
      supply: s,
      borrowed: b,
      currency: c,
    }
  datum
}

pub fn oracleAction(x: Int, t: Int, s: Int, b: Int) -> OracleAction {
  let redeemer =
    OracleUpdate { exchange: x, timestamp: t, supply: s, borrowed: b }
  redeemer
}

// fn oracleActionClose() -> OracleAction {
//   let redeemer = OracleClose
//   redeemer
// }

pub fn configDatum(l: ScriptHash, c: ScriptHash, r: ScriptHash) -> ConfigDatum {
  let datum = ConfigDatum { loanVal: l, colVal: c, rewardsVal: r }
  datum
}

pub fn configActionUpdate(
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

pub fn loanActionBalance() -> LoanAction {
  let redeemer = SLBalance
  redeemer
}

pub fn loanActionLiquidate() -> LoanAction {
  let redeemer = SLLiquidate
  redeemer
}

pub fn loanActionClose() -> LoanAction {
  let redeemer = SLClose
  redeemer
}

pub fn loanMintActionMint(a: Int, d: Int, t: Int) -> LoanMintAction {
  let redeemer = AMint { amount: a, rewards: 0, term: d, timestamp: t }
  redeemer
}

// fn loanMintActionBurn() -> LoanMintAction {
//   let redeemer = ABurn
//   redeemer
// }

pub fn loanDatum(a: Int, r: Int, t: Int, ti: Int, o: AssetName) -> LoanDatum {
  let datum =
    LoanDatum { amount: a, rewards: r, term: t, timestamp: ti, oracle: o }
  datum
}

pub fn collateralActionBalance() -> CollateralAction {
  let redeemer = SCBalance
  redeemer
}

pub fn collateralActionLiquidate() -> CollateralAction {
  let redeemer = SCLiquidate
  redeemer
}

pub fn collateralActionClose() -> CollateralAction {
  let redeemer = SCClose
  redeemer
}

pub fn collateralDatum(a: Int, t: Int, y: Int) -> CollateralDatum {
  let datum = CollateralDatum { amount: a, timestamp: t, yield: y }
  datum
}

pub fn rewardsActionMint() -> RewardsAction {
  let redeemer = RewardMint
  redeemer
}

// fn rewardsActionBurn() -> RewardsAction {
//   let redeemer = RewardMint
//   redeemer
// }

pub fn oracleMintActionMint(
  x: Int,
  ti: Int,
  c: ByteArray,
  su: Int,
  bo: Int,
  ba: Int,
  o: Int,
  s1: Int,
  s2: Int,
  te: Int,
) -> OracleMintAction {
  let redeemer =
    OMint {
      exchange: x,
      timestamp: ti,
      currency: c,
      supply: su,
      borrowed: bo,
      base: ba,
      optimal: o,
      slope1: s1,
      slope2: s2,
      term: te,
    }
  redeemer
}

// fn oracleMintActionBurn() -> OracleMintAction {
//   let redeemer = OBurn
//   redeemer
// }

//                  //
// Validator Inputs //
//                  //

pub fn configDatumIn() -> Datum {
  let configDatum =
    mConfigDatum(
      t.merkelLoanSpend,
      t.merkelCollateralSpend,
      t.rewardsMintHash,
      t.oracleValHash,
      t.interestValHash,
      t.yieldVault,
      [
        t.merkelCollateralBalance,
        t.merkelCollateralLiquidate,
        t.merkelCollateralClose,
        t.merkelBalance,
        t.merkelLiquidate,
        t.merkelClose,
      ],
    )
  InlineDatum(configDatum)
}

pub fn refConfigDatumIn() -> Datum {
  let configDatum =
    mConfigDatum(
      t.refLoanSpend,
      t.refCollateralSpend,
      t.refRewardsMint,
      t.refOracleSpend,
      t.refInterestSpend,
      t.refYieldSpend,
      [
        t.refBalance,
        t.refLiquidate,
        t.refClose,
        t.refRepay,
        t.refYieldIn,
        t.refYieldOut,
      ],
    )
  InlineDatum(configDatum)
}

pub fn oracleDatumIn(ratio: Int) -> Datum {
  let oracleInDatum = oracleDatum(ratio, 11111111, 1000000, 200000, "USD")

  InlineDatum(oracleInDatum)
}

pub fn loanDatumIn(value: Int) -> Datum {
  let loanDatum1 = loanDatum(value, value, 0, 1721819831, #"beef")
  InlineDatum(loanDatum1)
}

pub fn loanDatumIn0() -> Datum {
  let loanDatum1 = loanDatum(0, 1000, 0, 1721819831, #"beef")

  InlineDatum(loanDatum1)
}

pub fn collateralDatumIn(value: Int, yield: Int) -> Datum {
  let collateralDatum1 = collateralDatum(value, 1111111111, yield)
  InlineDatum(collateralDatum1)
}

pub fn oracleInput(ratio: Int) -> Input {
  let oracleIn =
    t.test_input(
      oref(#"dead", 6),
      t.test_output(
        t.test_script_address(t.oracleValHash),
        t.oracleValue(),
        oracleDatumIn(ratio),
      ),
    )
  oracleIn
}

pub fn refOracleInput(ratio: Int) -> Input {
  let oracleIn =
    t.test_input(
      oref(#"dead", 6),
      t.test_output(
        t.test_script_address(t.refOracleSpend),
        t.refOracleValue(),
        oracleDatumIn(ratio),
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
        t.test_script_address(t.interestValHash),
        t.oracleValue(),
        InlineDatum(interestDatum(base, optimal, slope1, slope2, term)),
      ),
    )

  interestIn
}

pub fn refInterestInput() -> Input {
  let base = 55
  let optimal = 70
  let slope1 = 40
  let slope2 = 300
  let term = 31556926

  let interestIn =
    t.test_input(
      oref(#"deaf", 8),
      t.test_output(
        t.test_script_address(t.refInterestSpend),
        t.refOracleValue(),
        InlineDatum(interestDatum(base, optimal, slope1, slope2, term)),
      ),
    )

  interestIn
}

pub fn configInput() -> Input {
  let configIn =
    t.test_input(
      oref(#"cece", 1),
      t.test_output(
        t.test_script_address(t.merkelConfigHash),
        t.configValue(),
        configDatumIn(),
      ),
    )
  configIn
}

pub fn refConfigInput() -> Input {
  let configIn =
    t.test_input(
      oref(#"cece", 1),
      t.test_output(
        t.test_script_address(t.refConfigSpend),
        t.refConfigValue(),
        refConfigDatumIn(),
      ),
    )
  configIn
}

pub fn loanInput(n: Int, amount: Int) -> Input {
  let loanIn =
    t.test_input(
      oref(#"face", n),
      t.test_output(
        t.test_script_address(t.merkelLoanSpend),
        t.loanTokenValue(),
        loanDatumIn(amount),
      ),
    )
  loanIn
}

pub fn refLoanInput(n: Int, amount: Int) -> Input {
  let loanIn =
    t.test_input(
      oref(#"face", n),
      t.test_output(
        t.test_script_address(t.refLoanSpend),
        t.refLoanTokenValue(),
        loanDatumIn(amount),
      ),
    )
  loanIn
}

pub fn multiLoanIn(loanToken: Value, amount: Int, index: Int) -> Input {
  let loanIn =
    t.test_input(
      oref(#"face", index),
      t.test_output(
        t.test_script_address(t.merkelLoanSpend),
        assets.merge(loanToken, assets.from_lovelace(2000000)),
        loanDatumIn(amount),
      ),
    )
  loanIn
}

pub fn refMultiLoanIn(loanToken: Value, amount: Int, index: Int) -> Input {
  let loanIn =
    t.test_input(
      oref(#"face", index),
      t.test_output(
        t.test_script_address(t.refLoanSpend),
        assets.merge(loanToken, assets.from_lovelace(2000000)),
        loanDatumIn(amount),
      ),
    )
  loanIn
}

pub fn collateralInput(_n: Int, amount: Int, value: Int, yield: Int) -> Input {
  let colIn =
    t.test_input(
      oref(#"cafe", 1),
      t.test_output(
        t.test_script_address(t.merkelCollateralSpend),
        assets.merge(t.makeAdaValue(value), t.loanTokenValue()),
        collateralDatumIn(amount, yield),
      ),
    )
  colIn
}

pub fn refCollateralInput(_n: Int, amount: Int, value: Int, yield: Int) -> Input {
  let colIn =
    t.test_input(
      oref(#"cafe", 1),
      t.test_output(
        t.test_script_address(t.refCollateralSpend),
        assets.merge(t.makeAdaValue(value), t.refLoanTokenValue()),
        collateralDatumIn(amount, yield),
      ),
    )
  colIn
}

pub fn multiCollateralIn(
  loanToken: Value,
  n: Int,
  amount: Int,
  value: Int,
  yield: Int,
) -> Input {
  let colIn =
    t.test_input(
      oref(#"cafe", n),
      t.test_output(
        t.test_script_address(t.merkelCollateralSpend),
        assets.merge(t.makeAdaValue(value), loanToken),
        collateralDatumIn(amount, yield),
      ),
    )
  colIn
}

pub fn refMultiCollateralIn(
  loanToken: Value,
  n: Int,
  amount: Int,
  value: Int,
  yield: Int,
) -> Input {
  let colIn =
    t.test_input(
      oref(#"cafe", n),
      t.test_output(
        t.test_script_address(t.refCollateralSpend),
        assets.merge(t.makeAdaValue(value), loanToken),
        collateralDatumIn(amount, yield),
      ),
    )
  colIn
}

pub fn userInput(value: Int) -> Input {
  let userIn1 =
    t.test_input(
      oref(#"feed", 9),
      t.test_output(t.test_address(#"cafe"), t.makeAdaValue(value), NoDatum),
    )
  userIn1
}

//                   //
// Validator Outputs //
//                   //

pub fn interestOutput(interest: Int) -> Output {
  let interestOut =
    t.test_output(
      t.test_address(#"deaf"),
      assets.from_lovelace(interest),
      NoDatum,
    )
  interestOut
}

pub fn refInterestOutput(interest: Int) -> Output {
  let interestOut =
    t.test_output(
      t.test_address(#"deaf"),
      assets.from_lovelace(interest),
      NoDatum,
    )
  interestOut
}

pub fn configOutput(datum: MerkelConfigDatum) -> Output {
  let configIn =
    t.test_output(
      t.test_script_address(t.merkelConfigHash),
      t.configValue(),
      InlineDatum(datum),
    )

  configIn
}

pub fn refConfigOutput(datum: MerkelConfigDatum) -> Output {
  let configIn =
    t.test_output(
      t.test_script_address(t.refConfigSpend),
      t.refConfigValue(),
      InlineDatum(datum),
    )

  configIn
}

pub fn oracleOutDatum(ratio: Int) -> Datum {
  let oracleOutDatum = oracleDatum(ratio, 1724449574, 1000000, 200000, "USD")
  InlineDatum(oracleOutDatum)
}

pub fn oracleOutput(ratio) -> Output {
  let oracleOut =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      t.oracleValue(),
      oracleOutDatum(ratio),
    )
  oracleOut
}

pub fn refOracleOutput(ratio) -> Output {
  let oracleOut =
    t.test_output(
      t.test_script_address(t.refOracleSpend),
      t.refOracleValue(),
      oracleOutDatum(ratio),
    )
  oracleOut
}

pub fn loanOutDatum(value: Int) -> Datum {
  let loanDatum1 = loanDatum(value, value, 0, 1724449574, #"beef")
  InlineDatum(loanDatum1)
}

pub fn loanOutput(value: Int) -> Output {
  let loanOut1 =
    t.test_output(
      t.test_script_address(t.merkelLoanSpend),
      t.loanTokenValue(),
      loanOutDatum(value),
    )
  loanOut1
}

pub fn refLoanOutput(value: Int) -> Output {
  let loanOut1 =
    t.test_output(
      t.test_script_address(t.refLoanSpend),
      t.refLoanTokenValue(),
      loanOutDatum(value),
    )
  loanOut1
}

pub fn multiLoanOut(loanToken: Value, value: Int) -> Output {
  let loanOut1 =
    t.test_output(
      t.test_script_address(t.merkelLoanSpend),
      assets.merge(loanToken, assets.from_lovelace(2000000)),
      loanOutDatum(value),
    )
  loanOut1
}

pub fn refMultiLoanOut(loanToken: Value, value: Int) -> Output {
  let loanOut1 =
    t.test_output(
      t.test_script_address(t.refLoanSpend),
      assets.merge(loanToken, assets.from_lovelace(2000000)),
      loanOutDatum(value),
    )
  loanOut1
}

pub fn collateralDatumOut(amount: Int, yield: Int) -> Datum {
  let collateralDatum = collateralDatum(amount, 12, yield)

  InlineDatum(collateralDatum)
}

pub fn collateralOutput(amount: Int, value: Int, yield: Int) -> Output {
  let colOut =
    t.test_output(
      t.test_script_address(t.merkelCollateralSpend),
      assets.merge(t.makeAdaValue(value), t.loanTokenValue()),
      collateralDatumOut(amount, yield),
    )
  colOut
}

pub fn refCollateralOutput(amount: Int, value: Int, yield: Int) -> Output {
  let colOut =
    t.test_output(
      t.test_script_address(t.refCollateralSpend),
      assets.merge(t.makeAdaValue(value), t.refLoanTokenValue()),
      collateralDatumOut(amount, yield),
    )
  colOut
}

pub fn multiCollateralOut(
  loanToken: Value,
  amount: Int,
  value: Int,
  yield: Int,
) -> Output {
  let colOut =
    t.test_output(
      t.test_script_address(t.merkelCollateralSpend),
      assets.merge(t.makeAdaValue(value), loanToken),
      collateralDatumOut(amount, yield),
    )
  colOut
}

pub fn refMultiCollateralOut(
  loanToken: Value,
  amount: Int,
  value: Int,
  yield: Int,
) -> Output {
  let colOut =
    t.test_output(
      t.test_script_address(t.refCollateralSpend),
      assets.merge(t.makeAdaValue(value), loanToken),
      collateralDatumOut(amount, yield),
    )
  colOut
}

pub fn withdrawal(script: ScriptHash) {
  let withdraw0 = [Pair(t.create_script_credential(script), 0)]
  // dict.from_ascending_pairs(
  //   [Pair(t.create_stake_credential(script), 0)],
  //   t.stakeCompare,
  // )
  withdraw0
}

//                        //
// Merkel Combined Inputs //
//                        //

pub fn mLoanInput(n: Int, amount: Int) -> Input {
  let loanIn =
    t.test_input(
      oref(#"face", n),
      t.test_output(
        t.test_script_address(t.mLoan),
        t.loanTokenValue(),
        loanDatumIn(amount),
      ),
    )
  loanIn
}

pub fn refMLoanInput(n: Int, amount: Int) -> Input {
  let loanIn =
    t.test_input(
      oref(#"face", n),
      t.test_output(
        t.test_script_address(t.refLoanSpend),
        t.refLoanTokenValue(),
        loanDatumIn(amount),
      ),
    )
  loanIn
}

pub fn mLoanIn(n: Int, amount: Int, loanToken: Value) -> Input {
  let loanIn =
    t.test_input(
      oref(#"face", n),
      t.test_output(
        t.test_script_address(t.mLoan),
        assets.merge(t.makeAdaValue(2), loanToken),
        loanDatumIn(amount),
      ),
    )
  loanIn
}

pub fn refMLoanIn(n: Int, amount: Int, loanToken: Value) -> Input {
  let loanIn =
    t.test_input(
      oref(#"face", n),
      t.test_output(
        t.test_script_address(t.refLoanSpend),
        assets.merge(t.makeAdaValue(2), loanToken),
        loanDatumIn(amount),
      ),
    )
  loanIn
}

pub fn mCollateralInput(n: Int, amount: Int, value: Int, yield: Int) -> Input {
  let colIn =
    t.test_input(
      oref(#"cafe", n),
      t.test_output(
        t.test_script_address(t.mCol),
        assets.merge(t.makeAdaValue(value), t.loanTokenValue()),
        collateralDatumIn(amount, yield),
      ),
    )
  colIn
}

pub fn refMCollateralInput(n: Int, amount: Int, value: Int, yield: Int) -> Input {
  let colIn =
    t.test_input(
      oref(#"cafe", n),
      t.test_output(
        t.test_script_address(t.refCollateralSpend),
        assets.merge(t.makeAdaValue(value), t.refLoanTokenValue()),
        collateralDatumIn(amount, yield),
      ),
    )
  colIn
}

pub fn mColIn(
  n: Int,
  amount: Int,
  value: Int,
  loanToken: Value,
  yield: Int,
) -> Input {
  let colIn =
    t.test_input(
      oref(#"cafe", n),
      t.test_output(
        t.test_script_address(t.mCol),
        assets.merge(t.makeAdaValue(value), loanToken),
        collateralDatumIn(amount, yield),
      ),
    )
  colIn
}

pub fn refMColIn(
  n: Int,
  amount: Int,
  value: Int,
  loanToken: Value,
  yield: Int,
) -> Input {
  let colIn =
    t.test_input(
      oref(#"cafe", n),
      t.test_output(
        t.test_script_address(t.refCollateralSpend),
        assets.merge(t.makeAdaValue(value), loanToken),
        collateralDatumIn(amount, yield),
      ),
    )
  colIn
}

pub fn mLoanOutput(value: Int) -> Output {
  let loanOut1 =
    t.test_output(
      t.test_script_address(t.mLoan),
      t.loanTokenValue(),
      loanOutDatum(value),
    )
  loanOut1
}

pub fn refMLoanOutput(value: Int) -> Output {
  let loanOut1 =
    t.test_output(
      t.test_script_address(t.refLoanSpend),
      t.refLoanTokenValue(),
      loanOutDatum(value),
    )
  loanOut1
}

pub fn mLoanOut(value: Int, loanToken: Value) -> Output {
  let loanOut1 =
    t.test_output(
      t.test_script_address(t.mLoan),
      assets.merge(t.makeAdaValue(2), loanToken),
      loanOutDatum(value),
    )
  loanOut1
}

pub fn refMLoanOut(value: Int, loanToken: Value) -> Output {
  let loanOut1 =
    t.test_output(
      t.test_script_address(t.refLoanSpend),
      assets.merge(t.makeAdaValue(2), loanToken),
      loanOutDatum(value),
    )
  loanOut1
}

pub fn mCollateralOutput(amount: Int, value: Int, yield: Int) -> Output {
  let colOut =
    t.test_output(
      t.test_script_address(t.mCol),
      assets.merge(t.makeAdaValue(value), t.loanTokenValue()),
      collateralDatumOut(amount, yield),
    )
  colOut
}

pub fn refMCollateralOutput(amount: Int, value: Int, yield: Int) -> Output {
  let colOut =
    t.test_output(
      t.test_script_address(t.refCollateralSpend),
      assets.merge(t.makeAdaValue(value), t.refLoanTokenValue()),
      collateralDatumOut(amount, yield),
    )
  colOut
}

pub fn mColOut(amount: Int, value: Int, loanToken: Value, yield: Int) -> Output {
  let colOut =
    t.test_output(
      t.test_script_address(t.mCol),
      assets.merge(t.makeAdaValue(value), loanToken),
      collateralDatumOut(amount, yield),
    )
  colOut
}

pub fn refMColOut(
  amount: Int,
  value: Int,
  loanToken: Value,
  yield: Int,
) -> Output {
  let colOut =
    t.test_output(
      t.test_script_address(t.refCollateralSpend),
      assets.merge(t.makeAdaValue(value), loanToken),
      collateralDatumOut(amount, yield),
    )
  colOut
}

//         //
// Context //
//         //

pub fn wCtx(script: ScriptHash, r: Data, tx: Transaction) -> ScriptContext {
  let ctx1 =
    ScriptContext { info: t.withPurpose(script), redeemer: r, transaction: tx }
  ctx1
}
