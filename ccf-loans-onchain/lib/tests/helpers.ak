use aiken/collection/list
use aiken/fuzz as f
use cardano/assets
use cardano/transaction.{InlineDatum, Input, NoDatum}
use ccfl/helpers as h
use tests/prop as p
use tests/tools as t
use tests/transactions as tx

// list of inputs

test get_loan_col_in(props via p.intHashList()) {
  expect [(h1, i1), (h2, i2), (h3, i3), (h4, i4), (h5, i5)] = props

  let loanToken = assets.from_asset(h1, h2, 1)

  let input1 =
    t.test_input(
      tx.oref(h1, i1),
      t.test_output(
        t.test_script_address(h1),
        assets.merge(t.makeAdaValue(i1), loanToken),
        InlineDatum(tx.loanDatum(i1, i2, i3, i4, "USD")),
      ),
    )

  let input2 =
    t.test_input(
      tx.oref(h2, i1),
      t.test_output(
        t.test_script_address(h2),
        assets.merge(t.makeAdaValue(i2), loanToken),
        InlineDatum(tx.collateralDatum(i1, i2, i3)),
      ),
    )

  let input3 =
    t.test_input(
      tx.oref(h3, i1),
      t.test_output(
        t.test_script_address(h3),
        assets.merge(t.makeAdaValue(i3), loanToken),
        NoDatum,
      ),
    )

  let input4 =
    t.test_input(
      tx.oref(h4, i1),
      t.test_output(
        t.test_script_address(h4),
        assets.merge(t.makeAdaValue(i4), loanToken),
        InlineDatum(tx.collateralDatum(i1, i2, i3)),
      ),
    )

  let input5 =
    t.test_input(
      tx.oref(h5, i1),
      t.test_output(
        t.test_script_address(h5),
        assets.merge(t.makeAdaValue(i5), loanToken),
        InlineDatum(tx.loanDatum(i1, i2, i3, i4, "USD")),
      ),
    )

  h.get_loan_col_in([input1, input2, input3, input4, input5], loanToken, h1, h2) == (
    input1.output.value,
    tx.loanDatum(i1, i2, i3, i4, "USD"),
    input2.output.value,
    tx.collateralDatum(i1, i2, i3),
  )
}

test get_loan_col_in_datum(props via p.intHashList()) {
  expect [(h1, i1), (h2, i2), (h3, i3), (h4, i4), (h5, i5)] = props

  let loanToken = assets.from_asset(h1, h2, 1)

  let input1 =
    t.test_input(
      tx.oref(h1, i1),
      t.test_output(
        t.test_script_address(h1),
        assets.merge(t.makeAdaValue(i1), loanToken),
        InlineDatum(tx.loanDatum(i1, i2, i3, i4, "USD")),
      ),
    )

  let input2 =
    t.test_input(
      tx.oref(h2, i1),
      t.test_output(
        t.test_script_address(h2),
        assets.merge(t.makeAdaValue(i2), loanToken),
        InlineDatum(tx.collateralDatum(i1, i2, i3)),
      ),
    )

  let input3 =
    t.test_input(
      tx.oref(h3, i1),
      t.test_output(
        t.test_script_address(h3),
        assets.merge(t.makeAdaValue(i3), loanToken),
        NoDatum,
      ),
    )

  let input4 =
    t.test_input(
      tx.oref(h4, i1),
      t.test_output(
        t.test_script_address(h4),
        assets.merge(t.makeAdaValue(i4), loanToken),
        InlineDatum(tx.collateralDatum(i1, i2, i3)),
      ),
    )

  let input5 =
    t.test_input(
      tx.oref(h5, i1),
      t.test_output(
        t.test_script_address(h5),
        assets.merge(t.makeAdaValue(i5), loanToken),
        InlineDatum(tx.loanDatum(i1, i2, i3, i4, "USD")),
      ),
    )

  h.get_loan_col_in_datum(
    [input1, input2, input3, input4, input5],
    loanToken,
    h1,
    h2,
  ) == (tx.loanDatum(i1, i2, i3, i4, "USD"), tx.collateralDatum(i1, i2, i3))
}

test get_config_datum(props via p.intHashList()) {
  expect [(h1, i1), (h2, i2), (h3, i3), (h4, i4), (h5, i5)] = props

  let loanToken = assets.from_asset(h1, h2, 1)

  let input1 =
    t.test_input(
      tx.oref(h1, i1),
      t.test_output(
        t.test_script_address(h1),
        assets.merge(t.makeAdaValue(i1), loanToken),
        tx.refConfigDatumIn(),
      ),
    )

  let input2 =
    t.test_input(
      tx.oref(h2, i1),
      t.test_output(
        t.test_script_address(h2),
        assets.merge(t.makeAdaValue(i2), loanToken),
        InlineDatum(tx.collateralDatum(i1, i2, i3)),
      ),
    )

  let input3 =
    t.test_input(
      tx.oref(h3, i1),
      t.test_output(
        t.test_script_address(h3),
        assets.merge(t.makeAdaValue(i3), loanToken),
        NoDatum,
      ),
    )

  let input4 =
    t.test_input(
      tx.oref(h4, i1),
      t.test_output(
        t.test_script_address(h4),
        assets.merge(t.makeAdaValue(i4), loanToken),
        InlineDatum(tx.collateralDatum(i1, i2, i3)),
      ),
    )

  let input5 =
    t.test_input(
      tx.oref(h5, i1),
      t.test_output(
        t.test_script_address(h5),
        assets.merge(t.makeAdaValue(i5), loanToken),
        InlineDatum(tx.loanDatum(i1, i2, i3, i4, "USD")),
      ),
    )

  h.get_config_datum([input1, input2, input3, input4, input5], h1) == tx.mConfigDatum(
    t.refLoanSpend,
    t.refCollateralSpend,
    t.refRewardsMint,
    t.refOracleSpend,
    t.refInterestSpend,
    t.refYieldSpend,
    [
      t.refBalance,
      t.refLiquidate,
      t.refClose,
      t.refRepay,
      t.refYieldIn,
      t.refYieldOut,
    ],
  )
}

test get_interest_datum(props via p.intHashList()) {
  expect [(h1, i1), (h2, i2), (h3, i3), (h4, i4), (h5, i5)] = props

  let loanToken = assets.from_asset(h1, h2, 1)

  let interestDatum = tx.interestDatum(i1, i2, i3, i4, i5)

  let input1 =
    t.test_input(
      tx.oref(h1, i1),
      t.test_output(
        t.test_script_address(h1),
        assets.merge(t.makeAdaValue(i1), loanToken),
        InlineDatum(interestDatum),
      ),
    )

  let input2 =
    t.test_input(
      tx.oref(h2, i1),
      t.test_output(
        t.test_script_address(h2),
        assets.merge(t.makeAdaValue(i2), loanToken),
        InlineDatum(tx.collateralDatum(i1, i2, i3)),
      ),
    )

  let input3 =
    t.test_input(
      tx.oref(h3, i1),
      t.test_output(
        t.test_script_address(h3),
        assets.merge(t.makeAdaValue(i3), loanToken),
        NoDatum,
      ),
    )

  let input4 =
    t.test_input(
      tx.oref(h4, i1),
      t.test_output(
        t.test_script_address(h4),
        assets.merge(t.makeAdaValue(i4), loanToken),
        InlineDatum(tx.collateralDatum(i1, i2, i3)),
      ),
    )

  let input5 =
    t.test_input(
      tx.oref(h5, i1),
      t.test_output(
        t.test_script_address(h5),
        assets.merge(t.makeAdaValue(i5), loanToken),
        InlineDatum(tx.loanDatum(i1, i2, i3, i4, "USD")),
      ),
    )

  h.get_interest_datum([input1, input2, input3, input4, input5], h1, h1) == interestDatum
}

test get_oracle_datum(props via p.intHashList()) {
  expect [(h1, i1), (h2, i2), (h3, i3), (h4, i4), (h5, i5)] = props

  let oracleToken = assets.from_asset(h1, h2, 1)

  let oracleDatum = tx.oracleDatum(i1, i2, i3, i4, h5)

  let output1 =
    t.test_output(
      t.test_script_address(h1),
      assets.merge(t.makeAdaValue(i1), oracleToken),
      InlineDatum(oracleDatum),
    )

  let output2 =
    t.test_output(
      t.test_script_address(h2),
      assets.merge(t.makeAdaValue(i2), oracleToken),
      InlineDatum(tx.collateralDatum(i1, i2, i3)),
    )

  let output3 =
    t.test_output(
      t.test_script_address(h3),
      assets.merge(t.makeAdaValue(i3), oracleToken),
      NoDatum,
    )

  let output4 =
    t.test_output(
      t.test_script_address(h4),
      assets.merge(t.makeAdaValue(i4), oracleToken),
      InlineDatum(tx.collateralDatum(i1, i2, i3)),
    )

  let output5 =
    t.test_output(
      t.test_script_address(h5),
      assets.merge(t.makeAdaValue(i5), oracleToken),
      InlineDatum(tx.loanDatum(i1, i2, i3, i4, "USD")),
    )

  h.get_oracle_datum([output1, output2, output3, output4, output5], h1, h1) == oracleDatum
}

test oneIO_List(props via p.intHashList()) {
  expect [(h1, i1), (h2, i2), (h3, i3), (h4, i4), (h5, i5)] = props

  let oracleToken = assets.from_asset(h1, h2, 1)

  let oracleDatum = tx.oracleDatum(i1, i2, i3, i4, h5)

  let oref = tx.oref(h1, i1)

  let input1 =
    t.test_input(
      tx.oref(h1, i1),
      t.test_output(
        t.test_script_address(h1),
        assets.merge(t.makeAdaValue(i1), oracleToken),
        InlineDatum(oracleDatum),
      ),
    )

  let input2 =
    t.test_input(
      tx.oref(h2, i1),
      t.test_output(
        t.test_script_address(h2),
        assets.merge(t.makeAdaValue(i2), oracleToken),
        InlineDatum(tx.collateralDatum(i1, i2, i3)),
      ),
    )

  let input3 =
    t.test_input(
      tx.oref(h3, i1),
      t.test_output(
        t.test_script_address(h3),
        assets.merge(t.makeAdaValue(i3), oracleToken),
        NoDatum,
      ),
    )

  let output1 =
    t.test_output(
      t.test_script_address(h1),
      assets.merge(t.makeAdaValue(i1), oracleToken),
      InlineDatum(oracleDatum),
    )

  let output2 =
    t.test_output(
      t.test_script_address(h2),
      assets.merge(t.makeAdaValue(i2), oracleToken),
      InlineDatum(tx.collateralDatum(i1, i2, i3)),
    )

  let output3 =
    t.test_output(
      t.test_script_address(h3),
      assets.merge(t.makeAdaValue(i3), oracleToken),
      NoDatum,
    )

  let inList =
    [input1, input2, input3]
  let outList =
    [output1, output2, output3]

  h.oneIO_List(oref, inList, outList) == (input1, output1)
}
