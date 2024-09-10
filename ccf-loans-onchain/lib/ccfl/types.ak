use aiken/crypto.{ScriptHash}
use cardano/assets.{AssetName}

//                    //
// Datums & Redeemers //
//                    //

pub type WithdrawRedeemer {
  Withdraw { a: List<Int> }
}

pub type ConfigDatum {
  loanVal: ScriptHash,
  colVal: ScriptHash,
  rewardsVal: ScriptHash,
}

pub type MerkelConfigDatum {
  loanVal: ScriptHash,
  colVal: ScriptHash,
  rewardsVal: ScriptHash,
  oracleVal: ScriptHash,
  interestVal: ScriptHash,
  yield: ScriptHash,
  collateralRedeemers: List<ScriptHash>,
}

pub type ConfigAction {
  ConUpdate { loanVal: ScriptHash, colVal: ScriptHash, rewardsVal: ScriptHash }
  ConClose
}

pub type MerkelConfigAction {
  MConUpdate {
    loanVal: ScriptHash,
    colVal: ScriptHash,
    rewardsVal: ScriptHash,
    oracleVal: ScriptHash,
    interestVal: ScriptHash,
    collateralRedeemers: List<ScriptHash>,
  }
  MConClose
}

pub type LoanAction {
  SLBalance
  SLLiquidate
  SLClose
}

pub type LoanMintAction {
  AMint { amount: Int, rewards: Int, term: Int, timestamp: Int }
  ABurn
}

pub type LoanDatum {
  amount: Int,
  rewards: Int,
  term: Int,
  timestamp: Int,
  oracle: AssetName,
}

pub type MerkelLoanAction {
  // index of withdrawalValidator
  // This is a reference to the redeemer case we are validating
  i: Int,
}

pub type CollateralAction {
  SCBalance
  SCLiquidate
  SCClose
}

pub type MerkelCollateralAction {
  i: Int,
}

pub type TCollateralDatum {
  amount: Int,
  timestamp: Int,
}

pub type CollateralDatum {
  amount: Int,
  timestamp: Int,
  yield: Int,
}

pub type RewardsAction {
  RewardMint
  RewardBurn
}

pub type OracleDatum {
  exchange: Int,
  timestamp: Int,
  currency: ByteArray,
  supply: Int,
  borrowed: Int,
}

pub type OracleAction {
  OracleUpdate { exchange: Int, timestamp: Int, supply: Int, borrowed: Int }
  OracleClose
}

pub type OracleMintAction {
  OMint {
    exchange: Int,
    timestamp: Int,
    currency: ByteArray,
    supply: Int,
    borrowed: Int,
    base: Int,
    optimal: Int,
    slope1: Int,
    slope2: Int,
    term: Int,
  }
  OBurn
}

pub type InterestDatum {
  base: Int,
  optimal: Int,
  slope1: Int,
  slope2: Int,
  term: Int,
}

pub type InterestAction {
  InterestUpdate {
    base: Int,
    optimal: Int,
    slope1: Int,
    slope2: Int,
    term: Int,
  }
  InterestClose
}

pub type YieldDatum {
  loan: ByteArray,
}

pub type YieldAction {
  i: Int,
}
