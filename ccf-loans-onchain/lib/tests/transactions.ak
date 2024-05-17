use aiken/time.{PosixTime}
use ccfl/types.{
  AMint, CollateralAction, CollateralDatum, ConUpdate, ConfigAction, ConfigDatum,
  LoanAction, LoanDatum, LoanMintAction, MerkelCollateralAction,
  MerkelConfigDatum, MerkelLoanAction, OMint, OracleAction, OracleDatum,
  OracleMintAction, OracleUpdate, RewardMint, RewardsAction, SCBalance, SCClose,
  SCLiquidate, SLBalance, SLClose, SLLiquidate, ScriptHash,
}

//                             //
// Transaction Testing Helpers //
//                             //

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
