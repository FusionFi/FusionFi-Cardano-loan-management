use aiken/hash.{Blake2b_224, Hash}
use aiken/time.{PosixTime}
use aiken/transaction/credential.{Script, VerificationKey}
use aiken/transaction/value.{PolicyId}

pub type VerificationKeyHash =
  Hash<Blake2b_224, VerificationKey>

pub type ScriptHash =
  Hash<Blake2b_224, Script>

//                    //
// Datums & Redeemers //
//                    //

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
  loanRedeemers: List<ScriptHash>,
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
    loanRedeemers: List<ScriptHash>,
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
  AMint { amount: Int, rewards: Int, term: Int, timestamp: PosixTime }
  ABurn
}

pub type LoanDatum {
  amount: Int,
  rewards: Int,
  term: Int,
  timestamp: PosixTime,
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

pub type CollateralDatum {
  amount: Int,
  timestamp: PosixTime,
}

pub type RewardsAction {
  RewardMint
  RewardBurn
}

pub type OracleDatum {
  exchange: Int,
  timestamp: PosixTime,
  interest: Int,
  fee: Int,
  currency: ByteArray,
}

pub type OracleAction {
  OracleUpdate { exchange: Int, timestamp: PosixTime, interest: Int, fee: Int }
  OracleClose
}

pub type OracleMintAction {
  OMint
  OBurn
}
