use cardano/assets
use cardano/transaction.{Input, NoDatum, Output, Transaction, placeholder}
use ccfl/helpers
use tests/tools as t

// Optimisation test functions //

test oneIO_Tx() {
  let oref = t.test_oref(#"baba", 1)

  let i1 =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(t.configValHash),
        assets.from_lovelace(200),
        NoDatum,
      ),
    )

  let i2 =
    t.test_input(
      t.test_oref(#"caba", 1),
      t.test_output(
        t.test_script_address(t.oracleValHash),
        assets.from_lovelace(200),
        NoDatum,
      ),
    )

  let i3 =
    t.test_input(
      t.test_oref(#"daba", 1),
      t.test_output(
        t.test_script_address(t.oracleValHash),
        assets.from_lovelace(200),
        NoDatum,
      ),
    )

  let o1 =
    t.test_output(
      t.test_script_address(t.configValHash),
      assets.from_lovelace(200),
      NoDatum,
    )

  let o2 =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      assets.from_lovelace(200),
      NoDatum,
    )

  let o3 =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      assets.from_lovelace(200),
      NoDatum,
    )
  let inList =
    [i1, i2, i3]
  let outList =
    [o1, o2, o3]

  let tx = Transaction { ..placeholder, inputs: inList, outputs: outList }
  helpers.oneIO_Tx(oref, tx) == Pair(i1, o1)
}

test oneIO_List() {
  let oref = t.test_oref(#"baba", 1)

  let i1 =
    t.test_input(
      oref,
      t.test_output(
        t.test_script_address(t.configValHash),
        assets.from_lovelace(200),
        NoDatum,
      ),
    )

  let i2 =
    t.test_input(
      t.test_oref(#"caba", 1),
      t.test_output(
        t.test_script_address(t.oracleValHash),
        assets.from_lovelace(200),
        NoDatum,
      ),
    )

  let i3 =
    t.test_input(
      t.test_oref(#"daba", 1),
      t.test_output(
        t.test_script_address(t.oracleValHash),
        assets.from_lovelace(200),
        NoDatum,
      ),
    )

  let o1 =
    t.test_output(
      t.test_script_address(t.configValHash),
      assets.from_lovelace(200),
      NoDatum,
    )
  let o2 =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      assets.from_lovelace(200),
      NoDatum,
    )

  let o3 =
    t.test_output(
      t.test_script_address(t.oracleValHash),
      assets.from_lovelace(200),
      NoDatum,
    )
  let inList =
    [i1, i2, i3]
  let outList =
    [o1, o2, o3]

  let tx = Transaction { ..placeholder, inputs: inList, outputs: outList }
  helpers.oneIO_List(oref, inList, outList) == Pair(i1, o1)
}
