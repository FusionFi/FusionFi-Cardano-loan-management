use aiken/hash.{Blake2b_224, Hash}
use aiken/time.{PosixTime}
use aiken/transaction.{
  Datum, InlineDatum, Input, Mint, Output, OutputReference, ScriptContext,
  ScriptPurpose, Spend, Transaction, TransactionId, WithdrawFrom,
}
use aiken/transaction/credential.{
  Address, Credential, Inline, Referenced, Script, ScriptCredential,
  VerificationKey, VerificationKeyCredential,
}
use aiken/transaction/value.{AssetName, MintedValue, PolicyId, Value}

pub const withLoanHash =
  #"4ec845bbc68fb454403c577635e5d934ead056c206f1e5b351f2d9ee"

pub const collateralValHash =
  #"c87cb59525bbb34ecaa261fa002ef290748317e1cbb0300aeeec62d7"

pub const configMintHash =
  #"0371cc59b8c81f47bb02a76b227f6ea74e7dfdf2b9e3270337637b01"

pub const configValHash =
  #"dfd0433a8e973bcb26919d59bd0afa094f49eaeb81931022b67f64a1"

pub const loanMintHash =
  #"13467ada0ce604c286b879e969231e206dbb95a41eca4722c963085b"

pub const loanValHash =
  #"8efc8a322434c86df29198ab3f95e7627cf55363177fc3e37abba552"

pub const oracleMintHash =
  #"d07d942ea4581f003c2daa0e14799a2ab10063eea81bcf0ea90d1841"

pub const oracleValHash =
  #"c3b2b1b43f51c93bd1e32f264c94f12bd118692aad403ed0454a3102"

pub const rewardsMintHash =
  #"a3d0ea91754e4b26492533f94545a25e7e2d71af53058a166bc77786"

pub type ScriptHash =
  Hash<Blake2b_224, Script>

//            //
// UTxO Tools //
//            //

pub fn configValue() -> Value {
  let lovelaceValue = value.from_lovelace(2)
  let configToken = configTokenValue()

  value.merge(lovelaceValue, configToken)
}

pub fn oracleValue() -> Value {
  let lovelaceValue = value.from_lovelace(2)
  let oracleToken = oracleTokenValue()

  value.merge(lovelaceValue, oracleToken)
}

pub fn loanValue() -> Value {
  let lovelaceValue = value.from_lovelace(2)
  let loanToken = loanTokenValue()

  value.merge(lovelaceValue, loanToken)
}

pub fn collateralValue() -> Value {
  let lovelaceValue = value.from_lovelace(2)
  let collateralToken = loanTokenValue()

  value.merge(lovelaceValue, collateralToken)
}

pub fn rewardsValue(i: Int) -> Value {
  let lovelaceValue = value.from_lovelace(2)
  let rewardsValue = rewardsTokenValue(i)
  value.merge(lovelaceValue, rewardsValue)
}

pub fn configMintedValue() -> MintedValue {
  let configToken = configTokenValue()

  value.to_minted_value(configToken)
}

pub fn rewardsMintedValue(i: Int) -> MintedValue {
  let rewardsToken = rewardsTokenValue(i)

  value.to_minted_value(rewardsToken)
}

pub fn loanMintedValue() -> MintedValue {
  let loanToken = loanTokenValue()

  value.to_minted_value(loanToken)
}

pub fn oracleMintedValue() -> MintedValue {
  let oracleToken = oracleTokenValue()

  value.to_minted_value(oracleToken)
}

//        //
// Assets //
//        //

pub fn configTokenValue() -> Value {
  let configToken = value.from_asset(configMintHash, #"face", 1)

  configToken
}

pub fn loanTokenValue() -> Value {
  let loanToken = value.from_asset(loanMintHash, #"cafe", 1)

  loanToken
}

pub fn oracleTokenValue() -> Value {
  let oracleToken = value.from_asset(oracleMintHash, #"beef", 1)

  oracleToken
}

pub fn rewardsTokenValue(i: Int) -> Value {
  let rewardsValue = value.from_asset(rewardsMintHash, #"", i)

  rewardsValue
}

//                 //
// Basic Functions //
//                 //

pub fn makePolicyId(s: ScriptHash) -> PolicyId {
  let policy = s
  policy
}

pub fn make_asset_name(tn: ByteArray) -> AssetName {
  let an = tn
  an
}

pub fn test_value_with_token() {
  todo
}

pub fn makeAdaValue(l: Int) -> Value {
  value.from_lovelace(l * 1000000)
}

pub fn test_input(oref: OutputReference, out: Output) -> Input {
  let in: Input = Input { output_reference: oref, output: out }
  in
}

pub fn test_output(a: Address, v: value.Value, d: Datum) -> Output {
  let out: Output =
    Output { address: a, value: v, datum: d, reference_script: None }
  out
}

// Create an OutputReference
pub fn test_oref(h: ByteArray, i: Int) -> OutputReference {
  let oref: OutputReference =
    OutputReference {
      transaction_id: TransactionId { hash: h },
      output_index: i,
    }
  oref
}

// Create ScriptContext
pub fn test_context(t: Transaction, p: ScriptPurpose) -> ScriptContext {
  let ctx = ScriptContext { transaction: t, purpose: p }
  ctx
}

// Create ScriptPurpose
pub fn test_mint_purpose(p: value.PolicyId) -> ScriptPurpose {
  Mint(p)
}

pub fn test_spend_purpose(o: OutputReference) -> ScriptPurpose {
  Spend(o)
}

pub fn testInlineDatum(d: Data) -> Datum {
  let datum = InlineDatum(d)
  datum
}

pub fn test_address(pkh: Hash<Blake2b_224, VerificationKey>) -> Address {
  let addr =
    Address {
      payment_credential: VerificationKeyCredential(pkh),
      stake_credential: None,
    }
  addr
}

pub fn test_script_address(s: Hash<Blake2b_224, Script>) -> Address {
  credential.from_script(s)
}

pub fn test_signatories() -> List<ByteArray> {
  [#"face"]
}

pub fn test_tx_id(h: ByteArray) -> TransactionId {
  let txid = TransactionId { hash: h }
  txid
}

// Testing Helper Functions //

pub fn create_stake_credential(
  s: Hash<Blake2b_224, Script>,
) -> Referenced<Credential> {
  Inline(ScriptCredential(s))
}

pub fn stakeCompare(
  left: Referenced<Credential>,
  right: Referenced<Credential>,
) -> Ordering {
  if left == right {
    Equal
  } else {
    Less
  }
}

pub fn scriptCompare(_left: ScriptPurpose, _right: ScriptPurpose) -> Ordering {
  Less
}

pub fn withPurpose(hash: ByteArray) -> ScriptPurpose {
  let stake = create_stake_credential(hash)
  WithdrawFrom(stake)
}
