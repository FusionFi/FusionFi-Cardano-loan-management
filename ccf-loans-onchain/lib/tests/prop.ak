use aiken/fuzz as f

pub type CollateralFuzz {
  colAmt: Int,
  colValue: Int,
}

// pub fn colFuzz(a: Int via f.int(), b: Int via f.int(), ) -> Fuzzer<CollateralFuzz> {

//   CollateralFuzz { colAmt: a, colValue: b }
// }

pub fn colFuzz() -> Fuzzer<(Int, Int)> {
  let a = f.int_between(1, 10)
  let b = f.int_between(1, 10)
  f.both(a, b)
}

pub fn twoInts() -> Fuzzer<(Int, Int)> {
  let a = f.int_between(1, 10)
  let b = f.int_between(1, 10)
  f.both(a, b)
}

pub fn threeInts() -> Fuzzer<(Int, Int, Int)> {
  f.map3(
    f.int_between(1, 10),
    f.int_between(1, 10),
    f.int_between(1, 10),
    fn(a, b, c) { (a, b, c) },
  )
}

pub fn fourInts() -> Fuzzer<(Int, Int, Int, Int)> {
  f.map4(
    f.int_between(1, 10),
    f.int_between(1, 10),
    f.int_between(1, 10),
    f.int_between(1, 10),
    fn(a, b, c, d) { (a, b, c, d) },
  )
}

pub fn loanTime() -> Fuzzer<(Int, Int)> {
  f.both(f.int_between(56926000, 31556926000), f.int_between(5, 50))
}
