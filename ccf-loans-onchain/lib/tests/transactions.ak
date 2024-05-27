use aiken/dict.{Dict}
use aiken/time.{PosixTime}
use aiken/transaction.{
  Datum, InlineDatum, Input, NoDatum, Output, OutputReference, ScriptContext,
  Transaction,
}
use aiken/transaction/value
use ccfl/types.{
  AMint, CollateralAction, CollateralDatum, ConUpdate, ConfigAction, ConfigDatum,
  LoanAction, LoanDatum, LoanMintAction, MerkelCollateralAction,
  MerkelConfigDatum, MerkelLoanAction, OMint, OracleAction, OracleDatum,
  OracleMintAction, OracleUpdate, RewardMint, RewardsAction, SCBalance, SCClose,
  SCLiquidate, SLBalance, SLClose, SLLiquidate, ScriptHash,
}
use tests/tools as t

//                             //
// Transaction Testing Helpers //
//                             //

pub fn oref(hash: ByteArray, index: Int) -> OutputReference {
  t.test_oref(hash, index)
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
  lR: List<ScriptHash>,
  cR: List<ScriptHash>,
) -> MerkelConfigDatum {
  let datum =
    MerkelConfigDatum {
      loanVal: l,
      colVal: c,
      rewardsVal: r,
      oracleVal: o,
      loanRedeemers: lR,
      collateralRedeemers: cR,
    }
  datum
}

pub fn oracleDatum(x: Int, t: PosixTime, r: Int, f: Int) -> OracleDatum {
  let datum = OracleDatum { usdAda: x, timestamp: t, rate: r, fee: f }
  datum
}

pub fn oracleAction(x: Int, t: PosixTime, r: Int, f: Int) -> OracleAction {
  let redeemer = OracleUpdate { usdAda: x, timestamp: t, rate: r, fee: f }
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

pub fn loanMintActionMint(c: ByteArray, v: Int, t: PosixTime) -> LoanMintAction {
  let redeemer = AMint { loanCurrency: c, loanValue: v, timestamp: t }
  redeemer
}

// fn loanMintActionBurn() -> LoanMintAction {
//   let redeemer = ABurn
//   redeemer
// }

pub fn loanDatum(a: Int, i: Int, r: Int, t: Int, ti: PosixTime) -> LoanDatum {
  let datum =
    LoanDatum { amount: a, interest: i, rewards: r, term: t, timestamp: ti }
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

pub fn collateralDatum(a: Int, t: PosixTime) -> CollateralDatum {
  let datum = CollateralDatum { amount: a, timestamp: t }
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

pub fn oracleMintActionMint() -> OracleMintAction {
  let redeemer = OMint
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
      [t.merkelLoanBalance, t.merkelLoanLiquidate, t.merkelLoanClose],
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

pub fn oracleDatumIn(ratio: Int) -> Datum {
  let oracleInDatum = oracleDatum(ratio, 11111111, 15, 2)

  InlineDatum(oracleInDatum)
}

pub fn loanDatumIn(value: Int) -> Datum {
  let loanDatum1 = loanDatum(value, 15, value, 0, 1111111111)
  InlineDatum(loanDatum1)
}

pub fn loanDatumIn0() -> Datum {
  let loanDatum1 = loanDatum(0, 15, 1000, 0, 1111111111)

  InlineDatum(loanDatum1)
}

pub fn collateralDatumIn(value: Int) -> Datum {
  let collateralDatum1 = collateralDatum(value, 1111111111)
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

pub fn configInput() -> Input {
  let configIn =
    t.test_input(
      oref(#"cece", 1),
      t.test_output(
        t.test_script_address(t.configValHash),
        t.configValue(),
        configDatumIn(),
      ),
    )
  configIn
}

pub fn loanInput(n: Int, amount: Int) -> Input {
  let loanIn =
    t.test_input(
      oref(#"face", 1),
      t.test_output(
        t.test_script_address(t.merkelLoanSpend),
        t.loanTokenValue(),
        loanDatumIn(amount),
      ),
    )
  loanIn
}

pub fn collateralInput(n: Int, amount: Int, value: Int) -> Input {
  let colIn =
    t.test_input(
      oref(#"cafe", 1),
      t.test_output(
        t.test_script_address(t.merkelCollateralSpend),
        value.merge(t.makeAdaValue(value), t.loanTokenValue()),
        collateralDatumIn(amount),
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

pub fn oracleOutDatum(ratio: Int) -> Datum {
  let oracleOutDatum = oracleDatum(ratio, 11111112, 15, 2)
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

pub fn loanOutDatum(value: Int) -> Datum {
  let loanDatum1 = loanDatum(value, 15, value, 0, 1111111111)
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

pub fn collateralDatumOut(amount: Int) -> Datum {
  let collateralDatum = collateralDatum(amount, 12)

  InlineDatum(collateralDatum)
}

pub fn collateralOutput(amount: Int, value: Int) -> Output {
  let colOut =
    t.test_output(
      t.test_script_address(t.merkelCollateralSpend),
      value.merge(t.makeAdaValue(value), t.loanTokenValue()),
      collateralDatumOut(amount),
    )
  colOut
}

pub fn withdrawal(script: ScriptHash) {
  let withdraw0 =
    dict.from_ascending_list(
      [(t.create_stake_credential(script), 0)],
      t.stakeCompare,
    )
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

pub fn mCollateralInput(n: Int, amount: Int, value: Int) -> Input {
  let colIn =
    t.test_input(
      oref(#"cafe", n),
      t.test_output(
        t.test_script_address(t.mCol),
        value.merge(t.makeAdaValue(value), t.loanTokenValue()),
        collateralDatumIn(amount),
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

pub fn mCollateralOutput(amount: Int, value: Int) -> Output {
  let colOut =
    t.test_output(
      t.test_script_address(t.mCol),
      value.merge(t.makeAdaValue(value), t.loanTokenValue()),
      collateralDatumOut(amount),
    )
  colOut
}

//         //
// Context //
//         //

pub fn wCtx(script: ScriptHash, tx: Transaction) -> ScriptContext {
  let ctx1 = ScriptContext { purpose: t.withPurpose(script), transaction: tx }
  ctx1
}
