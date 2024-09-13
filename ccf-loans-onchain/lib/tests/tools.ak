use aiken/crypto.{ScriptHash, VerificationKeyHash}
use cardano/address.{
  Address, Credential, Inline, Referenced, Script, StakeCredential,
  VerificationKey,
}
use cardano/assets.{AssetName, PolicyId, Value}
use cardano/script_context.{
  Minting, ScriptContext, ScriptInfo, Spending, Withdrawing,
}
use cardano/transaction.{
  Datum, InlineDatum, Input, Output, OutputReference, Transaction, TransactionId,
}

pub const refCollateralSpend =
  #"e7b19fcd79c6c08ca3a3be4f64683d4f2df442d743a89bcac8ffaa05"

pub const refConfigMint =
  #"a16c735c5d475021ec1705e54be108cca3d00dc10967044d2f99e056"

pub const refConfigSpend =
  #"a16c735c5d475021ec1705e54be108cca3d00dc10967044d2f99e056"

pub const refInterestSpend =
  #"102a28736ee8141cc74c99c2e89f5396d84854acd2e359537da3ecb9"

pub const refLoanMint =
  #"4b0552e32d8ccc1a60c40a2cf79cf257d8d842347076628d1795da7e"

pub const refLoanSpend =
  #"e7b19fcd79c6c08ca3a3be4f64683d4f2df442d743a89bcac8ffaa05"

pub const refBalance =
  #"33dc4568b0117965bd5cfac08ae55026a33d25a95e72a8d0740d1f1f"

pub const refClose = #"b1fe76df6d688a7593cd0073d3ab1edb39883b2d9bf9e85419d617cc"

pub const refLiquidate =
  #"3f0dcd6861f9386b68e1d805a164b07908d91b415f6c112729201f13"

pub const refRepay = #"688bcfcd072246ee9292f060319f3fd2c94c63de3106cb7cd306052f"

pub const refYieldIn =
  #"62252b72c3cf220388fd399f501215540f9dda321407e29b224e04a1"

pub const refYieldOut =
  #"94ff1b486f4a05754241f27c635f37219e258e5c1ec4c484531b6187"

pub const refOracleMint =
  #"af801486e4a94875536589f3ed919c46cb7eeacd38bad7798d3fc534"

pub const refOracleSpend =
  #"0c6813c37e200b21b9f71845a0ac67ee0d4be47b89e9984e89ed5239"

pub const refRewardsMint =
  #"42e3159a22e5123921d822b69e122ad2b8b44bd711f02192a5badf2b"

pub const refYieldSpend =
  #"e7b19fcd79c6c08ca3a3be4f64683d4f2df442d743a89bcac8ffaa05"

pub const yieldVault =
  #"4ab224562c1eb32a598374abec7cacd286a25ee46f23974d36ec9f15"

pub const yieldIn = #"91d9d0e0adb9afa3cc46d38a5bf79f41cf14ba16b5c7b0cca9b3f192"

pub const yieldOut = #"04c559ac2c8454682ddab0b9d630991ddc1bf426a7d1b4e3a1a405c1"

pub const interestValHash =
  #"102a28736ee8141cc74c99c2e89f5396d84854acd2e359537da3ecb9"

pub const merkelRepay =
  #"0d6b668668e8e4188b1bce4b798a6c22e089c74f722d43d79841e584"

pub const merkelClose =
  #"0d6b668668e8e4188b1bce4b798a6c22e089c74f722d43d79841e584"

pub const merkelLiquidate =
  #"d124f7244b69a2b3eca8ce0f09d6ec18ae65f3f58c19bb5adfb9cad5"

pub const merkelBalance =
  #"f80aed1df86acf38659b3b84e51d8005d1b63c4301143cefe6f577e2"

pub const mCol = #"4ab224562c1eb32a598374abec7cacd286a25ee46f23974d36ec9f15"

pub const mLoan = #"2a702bed15ddca531904e15f445074bcb2c766f90bfe65848e636227"

pub const merkelCollateralBalance =
  #"79bb35a6ac49e24289d3cb07c6258bb41b315cb2341fa71bfb43c9ab"

pub const merkelCollateralSpend =
  #"43024cb7526901f7ff2de25361a13980cf0e468e19603559fa10307d"

pub const merkelCollateralLiquidate =
  #"d124f7244b69a2b3eca8ce0f09d6ec18ae65f3f58c19bb5adfb9cad5"

pub const merkelCollateralClose =
  #"362a57053cade772680fe737f377e37497930af8012978a66eaafccb"

pub const merkelLoanBalance =
  #"f80aed1df86acf38659b3b84e51d8005d1b63c4301143cefe6f577e2"

pub const merkelLoanClose =
  #"85ae5150c9e0210cf0d53efea46ecc285814e4da35d26875520a65db"

pub const merkelLoanLiquidate =
  #"0d2bee45fe06c78f25ec4e50b2411970e3b1fe6603447899087001bc"

pub const merkelLoanSpend =
  #"8ed9b99679a54c1bf93924cc0dc79768d93fd2d450943294a27c9c67"

pub const merkelConfigHash =
  #"303618d7bba47b7181398325281cf01641a69a54951cbc76afc31c05"

pub const with2Hash =
  #"9c27818fc34b7a088a395cc09028359358810d1659a7379a7c8fd647"

pub const withLoanHash =
  #"4ec845bbc68fb454403c577635e5d934ead056c206f1e5b351f2d9ee"

pub const collateralValHash =
  #"b0269971c5f1cf4585d4eba416735cdc1d61007fef83c7efd5a3be8f"

pub const configMintHash =
  #"5f918d314f2c6dc85eda6d75fabd3cac6968577a51f72be927fd0918"

pub const configValHash =
  #"dfd0433a8e973bcb26919d59bd0afa094f49eaeb81931022b67f64a1"

pub const loanMintHash =
  #"d86cea3f277830bcd18238e2800d8fbec3cc6131166969a7be93a821"

pub const loanValHash =
  #"4ab224562c1eb32a598374abec7cacd286a25ee46f23974d36ec9f15"

pub const oracleMintHash =
  #"af801486e4a94875536589f3ed919c46cb7eeacd38bad7798d3fc534"

pub const oracleValHash =
  #"0c6813c37e200b21b9f71845a0ac67ee0d4be47b89e9984e89ed5239"

pub const rewardsMintHash =
  #"1fa867076dae742a37027eb2ed169455c32e183f621a525df69b85eb"

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

pub fn refCollateralRedeemers() -> List<ScriptHash> {
  let list =
    [refBalance, refLiquidate, refClose, refRepay, refYieldIn, refYieldOut]
  list
}

//            //
// UTxO Tools //
//            //

pub fn configValue() -> Value {
  let lovelaceValue = assets.from_lovelace(2)
  let configToken = configTokenValue()

  assets.merge(lovelaceValue, configToken)
}

pub fn refConfigValue() -> Value {
  let lovelaceValue = assets.from_lovelace(2)
  let configToken = refConfigTokenValue()

  assets.merge(lovelaceValue, configToken)
}

pub fn oracleValue() -> Value {
  let lovelaceValue = assets.from_lovelace(2)
  let oracleToken = oracleTokenValue()

  assets.merge(lovelaceValue, oracleToken)
}

pub fn refOracleValue() -> Value {
  let lovelaceValue = assets.from_lovelace(2)
  let oracleToken = refOracleTokenValue()

  assets.merge(lovelaceValue, oracleToken)
}

pub fn loanValue() -> Value {
  let lovelaceValue = assets.from_lovelace(2)
  let loanToken = loanTokenValue()

  assets.merge(lovelaceValue, loanToken)
}

pub fn refLoanValue() -> Value {
  let lovelaceValue = assets.from_lovelace(2)
  let loanToken = refLoanTokenValue()

  assets.merge(lovelaceValue, loanToken)
}

pub fn collateralValue() -> Value {
  let lovelaceValue = assets.from_lovelace(2)
  let collateralToken = loanTokenValue()

  assets.merge(lovelaceValue, collateralToken)
}

pub fn refCollateralValue(l: Int) -> Value {
  let lovelaceValue = makeAdaValue(l)
  let collateralToken = refLoanTokenValue()

  assets.merge(lovelaceValue, collateralToken)
}

pub fn rewardsValue(i: Int) -> Value {
  let lovelaceValue = assets.from_lovelace(2)
  let rewardsValue = rewardsTokenValue(i)
  assets.merge(lovelaceValue, rewardsValue)
}

pub fn refRewardsValue(i: Int) -> Value {
  let lovelaceValue = assets.from_lovelace(2)
  let rewardsValue = refRewardsTokenValue(i)
  assets.merge(lovelaceValue, rewardsValue)
}

pub fn configMintedValue() -> Value {
  let configToken = configTokenValue()

  configToken
}

pub fn refConfigMintedValue() -> Value {
  let configToken = refConfigTokenValue()

  configToken
}

pub fn rewardsMintedValue(i: Int) -> Value {
  let rewardsToken = rewardsTokenValue(i)

  rewardsToken
}

pub fn refRewardsMintedValue(i: Int) -> Value {
  let rewardsToken = rewardsTokenValue(i)

  rewardsToken
}

pub fn loanMintedValue() -> Value {
  let loanToken = loanTokenValue()

  loanToken
}

pub fn refLoanMintedValue() -> Value {
  let loanToken = refLoanTokenValue()

  loanToken
}

pub fn oracleMintedValue() -> Value {
  let oracleToken = oracleTokenValue()
  let interestToken = oracleTokenValue()
  let combinedValue = assets.merge(oracleToken, interestToken)

  combinedValue
}

pub fn refOracleMintedValue() -> Value {
  let oracleToken = refOracleTokenValue()
  let interestToken = refOracleTokenValue()
  let combinedValue = assets.merge(oracleToken, interestToken)

  combinedValue
}

//        //
// Assets //
//        //

pub fn configTokenValue() -> Value {
  let configToken = assets.from_asset(configMintHash, #"face", 1)

  configToken
}

pub fn refConfigTokenValue() -> Value {
  let configToken = assets.from_asset(refConfigMint, #"face", 1)

  configToken
}

pub fn loanTokenValue() -> Value {
  let loanToken = assets.from_asset(loanMintHash, #"cafe", 1)

  loanToken
}

pub fn refLoanTokenValue() -> Value {
  let loanToken = assets.from_asset(refLoanMint, #"cafe", 1)

  loanToken
}

pub fn loanBurnValue() -> Value {
  let loanBurn = assets.from_asset(loanMintHash, #"cafe", -2)

  loanBurn
}

pub fn refLoanBurnValue() -> Value {
  let loanBurn = assets.from_asset(refLoanMint, #"cafe", -2)

  loanBurn
}

pub fn oracleTokenValue() -> Value {
  let oracleToken = assets.from_asset(oracleMintHash, #"beef", 1)

  oracleToken
}

pub fn refOracleTokenValue() -> Value {
  let oracleToken = assets.from_asset(refOracleMint, #"beef", 1)

  oracleToken
}

pub fn rewardsTokenValue(i: Int) -> Value {
  let rewardsValue = assets.from_asset(rewardsMintHash, #"", i)

  rewardsValue
}

pub fn refRewardsTokenValue(i: Int) -> Value {
  let rewardsValue = assets.from_asset(refRewardsMint, #"", i)

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
  assets.from_lovelace(l * 1000000)
}

pub fn test_input(oref: OutputReference, out: Output) -> Input {
  let in: Input = Input { output_reference: oref, output: out }
  in
}

pub fn test_output(a: Address, v: Value, d: Datum) -> Output {
  let out: Output =
    Output { address: a, value: v, datum: d, reference_script: None }
  out
}

// Create an OutputReference
pub fn test_oref(h: ByteArray, i: Int) -> OutputReference {
  let oref: OutputReference =
    OutputReference { transaction_id: h, output_index: i }
  oref
}

// Create ScriptContext
pub fn test_context(t: Transaction, r: Data, p: ScriptInfo) -> ScriptContext {
  let ctx = ScriptContext { transaction: t, redeemer: r, info: p }
  ctx
}

// Create ScriptPurpose
pub fn test_mint_purpose(p: PolicyId) -> ScriptInfo {
  Minting(p)
}

pub fn test_spend_purpose(o: OutputReference, d: Option<Data>) -> ScriptInfo {
  Spending(o, d)
}

pub fn testInlineDatum(d: Data) -> Datum {
  let datum = InlineDatum(d)
  datum
}

pub fn test_address(pkh: VerificationKeyHash) -> Address {
  let addr =
    Address { payment_credential: VerificationKey(pkh), stake_credential: None }
  addr
}

pub fn test_script_address(s: ScriptHash) -> Address {
  address.from_script(s)
}

pub fn test_signatories() -> List<ByteArray> {
  [#"face"]
}

pub fn test_tx_id(h: ByteArray) -> TransactionId {
  let txid = h
  txid
}

// Testing Helper Functions //

pub fn create_stake_credential(s: ScriptHash) -> StakeCredential {
  Inline(Script(s))
}

pub fn create_script_credential(s: ScriptHash) -> Credential {
  Script(s)
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

pub fn scriptCompare(_left: ScriptInfo, _right: ScriptInfo) -> Ordering {
  Less
}

pub fn withPurpose(hash: ByteArray) -> ScriptInfo {
  // let stake = create_stake_credential(hash)
  let cred = create_script_credential(hash)
  Withdrawing(cred)
}
