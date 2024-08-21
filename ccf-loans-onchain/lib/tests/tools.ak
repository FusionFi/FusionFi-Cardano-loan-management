use aiken/hash.{Blake2b_224, Hash}
use aiken/transaction.{
  Datum, InlineDatum, Input, Mint, Output, OutputReference, ScriptContext,
  ScriptPurpose, Spend, Transaction, TransactionId, WithdrawFrom,
}
use aiken/transaction/credential.{
  Address, Credential, Inline, Referenced, Script, ScriptCredential,
  StakeCredential, VerificationKey, VerificationKeyCredential,
}
use aiken/transaction/value.{AssetName, MintedValue, PolicyId, Value}

pub const yieldIn = #"3c30a1becdf0b0f35e0f575031d793333200a13beb08a5afb35a5bc6"

pub const yieldOut = #"0f9f51c83f607b8131e2d62ccf0cb9d7406d080e303478013914ac91"

pub const interestValHash =
  #"8776cedf0c2677a95328e64f05de2c142a39f4ed9bf7ec877cc93352"

pub const merkelRepay =
  #"1e356ca1c4624f748adbfd5b999a3a3c69b66bc94ed040ffefd639fc"

pub const merkelClose =
  #"93fb1f13c199bdb5ec24cc6b171a7f57448c9cab20c5de7068619d4c"

pub const merkelLiquidate =
  #"98d51e724cde8f5a8469eade0c945db6be1a286318a5746987f5f116"

pub const merkelBalance =
  #"5a865ee240f36e9bbbadc6f7a6c11496635e194ec7e844d8b3fa8b13"

pub const mCol = #"da4485829d7239913cb82a2153b96f241eb1a0949b2675acfe156c32"

pub const mLoan = #"2a702bed15ddca531904e15f445074bcb2c766f90bfe65848e636227"

pub const merkelCollateralBalance =
  #"79bb35a6ac49e24289d3cb07c6258bb41b315cb2341fa71bfb43c9ab"

pub const merkelCollateralSpend =
  #"43024cb7526901f7ff2de25361a13980cf0e468e19603559fa10307d"

pub const merkelCollateralLiquidate =
  #"b57379e419301de61c5c8c61691f201f3e4f6046b3f84d0fc017d923"

pub const merkelCollateralClose =
  #"fa49216105e73d332940a48fc193649569a00e336966973a41f2654d"

pub const merkelLoanBalance =
  #"af19877e58beb387a1d385fa8b7179cf01372760af9b0478a01de4bf"

pub const merkelLoanClose =
  #"85ae5150c9e0210cf0d53efea46ecc285814e4da35d26875520a65db"

pub const merkelLoanLiquidate =
  #"0d2bee45fe06c78f25ec4e50b2411970e3b1fe6603447899087001bc"

pub const merkelLoanSpend =
  #"8ed9b99679a54c1bf93924cc0dc79768d93fd2d450943294a27c9c67"

pub const merkelConfigHash =
  #"d77f5ddbed7a4414fe8e67ec425ee535622ebcf3d4b13ba714665254"

pub const with2Hash =
  #"9c27818fc34b7a088a395cc09028359358810d1659a7379a7c8fd647"

pub const withLoanHash =
  #"4ec845bbc68fb454403c577635e5d934ead056c206f1e5b351f2d9ee"

pub const collateralValHash =
  #"b0269971c5f1cf4585d4eba416735cdc1d61007fef83c7efd5a3be8f"

pub const configMintHash =
  #"465b6d5e13a08408883d4d25989763b81225e651122e28c652fb21a3"

pub const configValHash =
  #"dfd0433a8e973bcb26919d59bd0afa094f49eaeb81931022b67f64a1"

pub const loanMintHash =
  #"72665d1296a02de7a60c8c644aec48a14bb558b9507923f1b7641572"

pub const loanValHash =
  #"b99df998781a5ad58093daca046840f09754e67f69f5c19e2bc2a1b3"

pub const oracleMintHash =
  #"4c81c3e1ab80ad6798a91aff70859fdadf8cf624ea9203539904e479"

pub const oracleValHash =
  #"61916fdcbf8e96ac8c9a144c0f98475d65d3b5ed3aa8f8ada8750b2b"

pub const rewardsMintHash =
  #"769a73b2bc482bf87d1482597ef7826ad5bb9f80010a8013a2d98300"

pub type ScriptHash =
  Hash<Blake2b_224, Script>

pub fn loanRedeemers() -> List<ScriptHash> {
  let list =
    [merkelLoanBalance, merkelLoanLiquidate, merkelLoanClose]
  list
}

pub fn collateralRedeemers() -> List<ScriptHash> {
  let list =
    [mCol, mLoan, merkelBalance, merkelLiquidate, merkelClose, merkelRepay]
  list
}

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
  let interestToken = oracleTokenValue()
  let combinedValue = value.merge(oracleToken, interestToken)

  value.to_minted_value(combinedValue)
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

pub fn loanBurnValue() -> Value {
  let loanBurn = value.from_asset(loanMintHash, #"cafe", -2)

  loanBurn
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

// pub fn test_value_with_token() {
//   todo
// }

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

pub fn create_stake_credential(s: Hash<Blake2b_224, Script>) -> StakeCredential {
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
