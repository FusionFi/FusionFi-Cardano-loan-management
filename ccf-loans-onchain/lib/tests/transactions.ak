use aiken/time.{PosixTime}
use ccfl/types.{
  AMint, CollateralAction, CollateralDatum, ConUpdate, ConfigAction, ConfigDatum,
  LoanAction, LoanDatum, LoanMintAction, OMint, OracleAction, OracleDatum,
  OracleMintAction, OracleUpdate, RewardMint, RewardsAction, SCBalance,
  SLBalance, ScriptHash,
}

//                             //
// Transaction Testing Helpers //
//                             //

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

// fn loanActionLiquidate() -> LoanAction {
//   let redeemer = SLLiquidate
//   redeemer
// }

// fn loanActionClose() -> LoanAction {
//   let redeemer = SLClose
//   redeemer
// }

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

// fn collateralActionLiquidate() -> CollateralAction {
//   let redeemer = SCLiquidate
//   redeemer
// }

// fn collateralActionClose() -> CollateralAction {
//   let redeemer = SCClose
//   redeemer
// }

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

// use aiken/dict
// use aiken/interval.{Interval, IntervalBound, NegativeInfinity, PositiveInfinity}
// use aiken/transaction.{Input, NoDatum, Output, Transaction, placeholder}
// use aiken/transaction/value
// use tests/tools.{
//   ScriptHash, collateralValHash, configMintHash, configValHash, loanMintHash,
//   loanValHash, makeAdaValue, makePolicyId, make_asset_name, oracleDatum,
//   oracleMintActionMint, oracleMintHash, oracleValHash, rewardsMintHash,
//   test_address, test_context, test_input, test_mint_purpose, test_oref,
//   test_output, test_script_address, test_signatories, test_spend_purpose,
//   test_tx_id,
// }

// //                        //
// // Validator Transactions //
// //                        //

// // pub fn configOutput() -> Output {
// //   let l =
// //     ScriptCredential(
// //       #"8efc8a322434c86df29198ab3f95e7627cf55363177fc3e37abba552",
// //     )
// //   let c =
// //     ScriptCredential(
// //       #"c87cb59525bbb34ecaa261fa002ef290748317e1cbb0300aeeec62d7",
// //     )
// //   let r =
// //     ScriptCredential(
// //       #"a3d0ea91754e4b26492533f94545a25e7e2d71af53058a166bc77786",
// //     )
// //   let datum = configDatum(l, c, r)
// //   let address = 
// //   let value = 
// // }

// pub fn test_oracle_mints_transaction() -> Transaction {
//   let tx =
//     Transaction {
//       inputs: [
//         test_input(
//           test_oref(#"cafe", 1),
//           test_output(test_address(#"face"), makeAdaValue(10), NoDatum),
//         ),
//       ],
//       reference_inputs: [],
//       outputs: [],
//       fee: value.zero(),
//       mint: value.to_minted_value(value.zero()),
//       certificates: [],
//       withdrawals: dict.new(),
//       validity_range: Interval {
//         lower_bound: IntervalBound {
//           bound_type: NegativeInfinity,
//           is_inclusive: True,
//         },
//         upper_bound: IntervalBound {
//           bound_type: PositiveInfinity,
//           is_inclusive: True,
//         },
//       },
//       extra_signatories: test_signatories(),
//       redeemers: dict.insert(
//         dict.new(),
//         key: "purpose",
//         value: test_mint_purpose(oracleMintHash),
//         oracleMintActionMint(),
//         compare,
//       ),
//       datums: dict.new(oracleMintHash, oracleDatum(1, 11111111, 15, 2)),
//       id: TransactionId { hash: #"" },
//     }
//   tx
// }

// //                 //
// // Validator UTxOs //
// //                 //

// // Oracle //

// pub fn oracleInput(
//   index: Int,
//   oracleScript: ScriptHash,
//   oracleMint: ByteArray,
// ) -> Input {
//   let txid = test_tx_id(#"")
//   let idx = index
//   let oref = test_oref(txid, idx)
//   let addr = test_script_address(oracleScript)
//   let value = test_value_with_token()
//   let out = test_output(addr, value, datum)
//   let input = test_input(oref, out)
// }

// pub fn oracleOutput() -> Output {
//   todo
// }

// pub fn oracleMintOutput() -> Output {
//   todo
// }

// pub fn configMintOutput() -> Output {
//   todo
// }

// pub fn configOutput() -> Output {
//   todo
// }

// pub fn configInput() -> Output {
//   todo
// }

// pub fn configRefInput() -> Input {
//   todo
// }

// pub fn rewardsOutput() -> Output {
//   todo
// }

// pub fn loanMintOutput() -> Output {
//   todo
// }

// pub fn loanValOutput() -> Output {
//   todo
// }

// pub fn loanValInput() -> Input {
//   todo
// }

// pub fn collateralOutput() -> Output {
//   todo
// }

// pub fn collateralInput() -> Output {
//   todo
// }
