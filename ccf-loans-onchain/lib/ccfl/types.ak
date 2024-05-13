use aiken/dict.{to_list}
use aiken/hash.{Blake2b_224, Hash}
use aiken/list.{any, filter, find, has, head}
use aiken/time.{PosixTime}
use aiken/transaction.{
  InlineDatum, Input, Mint, NoDatum, Output, ScriptContext, Spend, Transaction,
  find_input, find_script_outputs, placeholder,
}
use aiken/transaction/credential.{Script, ScriptCredential, VerificationKey}
use aiken/transaction/value.{PolicyId, flatten, lovelace_of, tokens}
use tests/tools as t

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
  oracleVal: ScriptHash,
  loanRedeemers: List<ScriptHash>,
  collateralRedeemers: List<ScriptHash>,
}

pub type ConfigAction {
  ConUpdate { loanVal: ScriptHash, colVal: ScriptHash, rewardsVal: ScriptHash }
  ConClose
}

pub type LoanAction {
  SLBalance
  SLLiquidate
  SLClose
}

pub type LoanMintAction {
  AMint { loanCurrency: ByteArray, loanValue: Int, timestamp: PosixTime }
  ABurn
}

pub type LoanDatum {
  amount: Int,
  interest: Int,
  rewards: Int,
  term: Int,
  timestamp: PosixTime,
}

type MerkelLoanAction {
  // index of withdrawalValidator
  // This is a reference to the redeemer case we are validating
  i: Int,
}

pub type CollateralAction {
  SCBalance
  SCLiquidate
  SCClose
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
  usdAda: Int,
  timestamp: PosixTime,
  rate: Int,
  fee: Int,
}

pub type OracleAction {
  OracleUpdate { usdAda: Int, timestamp: PosixTime, rate: Int, fee: Int }
  OracleClose
}

pub type OracleMintAction {
  OMint
  OBurn
}
