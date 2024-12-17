use aiken/crypto.{ScriptHash}
use cardano/assets.{AssetName, PolicyId}

//                    //
// Datums & Redeemers //
//                    //

pub type WithdrawAction {
  Withdraw { a: List<Int> }
}

pub type MerkelConfigDatum {
  loanVal: ScriptHash,
  colVal: ScriptHash,
  oracleVal: ScriptHash,
  interestVal: ScriptHash,
  supplyVal: ScriptHash,
  collateralRedeemers: List<ScriptHash>,
  supplyRedeemers: List<ScriptHash>,
}

pub type MerkelConfigAction {
  MConUpdate {
    loanVal: ScriptHash,
    colVal: ScriptHash,
    oracleVal: ScriptHash,
    interestVal: ScriptHash,
    supplyVal: ScriptHash,
    collateralRedeemers: List<ScriptHash>,
    supplyRedeemers: List<ScriptHash>,
  }
  MConClose
}

pub type LoanMintAction {
  AMint { amount: Int, rewards: Int, term: Int, timestamp: Int, pkh: ByteArray }
  ABurn
}

pub type LoanDatum {
  amount: Int,
  rewards: Int,
  term: Int,
  timestamp: Int,
  oracle: AssetName,
  pkh: ByteArray,
}

pub type MerkelLoanAction {
  // index of withdrawalValidator
  // This is a reference to the redeemer case we are validating
  i: Int,
}

pub type MerkelCollateralAction {
  i: Int,
}

pub type CollateralDatum {
  amount: Int,
  timestamp: Int,
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

pub type SupplyAction {
  SSupply { value: Int }
  SLend { value: Int }
  SWithdraw { value: Int }
  SClose
}

// V1
pub type SupplyDatum1 {
  policy: PolicyId,
  asset: AssetName,
  oracle: ByteArray,
}

// V2
pub type SupplyDatum {
  policy: ByteArray,
  // USDM
  asset: ByteArray,
}

// SupplyPolicy.USDM

pub type SupplyMintAction {
  LPMint { value: Int }
  LPBurn
}

pub type MSupplyAction {
  i: Int,
}
