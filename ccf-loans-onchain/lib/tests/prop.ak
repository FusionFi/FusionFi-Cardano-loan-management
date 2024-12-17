use aiken/collection/list
use aiken/fuzz as f

//                //
// Custom Fuzzers //
//                //

// creates list of 5 x 28' bytearrays
pub fn hashList() -> Fuzzer<List<ByteArray>> {
  f.list_between(f.bytearray_fixed(28), 5, 5)
}

// creates list of 5 x Ints 1-10
pub fn intList() -> Fuzzer<List<Int>> {
  f.list_between(f.int_between(1, 10), 5, 5)
}

// creates 5 x (hash, int) Tuples
pub fn intHashList() -> Fuzzer<List<(ByteArray, Int)>> {
  f.map2(
    hashList(),
    intList(),
    fn(a, b) { list.map2(a, b, fn(a, b) { (a, b) }) },
  )
}

// redundant
pub fn colFuzz() -> Fuzzer<(Int, Int)> {
  let a = f.int_between(1, 10)
  let b = f.int_between(1, 10)
  f.both(a, b)
}

// tuple of ints between 1-10
pub fn twoInts() -> Fuzzer<(Int, Int)> {
  let a = f.int_between(1, 10)
  let b = f.int_between(1, 10)
  f.both(a, b)
}

// tuple of ints between 1-10
pub fn threeInts() -> Fuzzer<(Int, Int, Int)> {
  f.map3(
    f.int_between(1, 10),
    f.int_between(1, 10),
    f.int_between(1, 10),
    fn(a, b, c) { (a, b, c) },
  )
}

// tuple of ints between 1-10
pub fn fourInts() -> Fuzzer<(Int, Int, Int, Int)> {
  f.map4(
    f.int_between(1, 10),
    f.int_between(1, 10),
    f.int_between(1, 10),
    f.int_between(1, 10),
    fn(a, b, c, d) { (a, b, c, d) },
  )
}

// tuple of ints one for PosixTime and one for interest payment
pub fn loanTime() -> Fuzzer<(Int, Int)> {
  f.both(f.int_between(56926000, 31556926000), f.int_between(5, 50))
}
