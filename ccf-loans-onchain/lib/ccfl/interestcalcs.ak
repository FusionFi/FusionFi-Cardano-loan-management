use aiken/string

// type InterestDatum {
//   supply: Int,
//   borrowed: Int,
//   base: Int,
//   optimal: Int,
//   slope1: Int,
//   slope2: Int,
//   term: Int,
//   loan: Int,
//   ratio: Int,
// }

pub fn utilisationRatio(borrowed: Int, supply: Int) -> Int {
  borrowed / supply
}

test utilisationRate() {
  let supply = 10
  let borrowed = 50
  utilisationRatio(borrowed, supply) == 5
}

// we will need to multiply && divide the result from here to account for a decimal value

pub fn interestSlope1(
  base: Int,
  optimal: Int,
  slope1: Int,
  supply: Int,
  borrowed: Int,
) -> Int {
  let ratio = utilisationRatio(borrowed, supply) * 100000
  // trace string.from_int(ratio)
  let utilisation = ratio / optimal
  // trace string.from_int(utilisation)
  let variableFee = utilisation * slope1
  // trace string.from_int(variableFee)
  let calculation = base * 10000 + variableFee
  calculation / 100 + 1
}

test slope1() {
  let base = 55
  // need to / 10 to account for the decimal
  let optimal = 70
  let slope1 = 40
  // need to / 10 to account for decimal
  let supply = 1000000
  let borrowed = 500000 * 10

  // we need to multiply values then divide out to get the correct % because Cardano doesnt do decimals
  // we add 1 at the end to round up to 3 decimals
  interestSlope1(base, optimal, slope1, supply, borrowed) == 8357
}

pub fn interestSlope2(
  base: Int,
  optimal: Int,
  slope1: Int,
  slope2: Int,
  supply: Int,
  borrowed: Int,
) -> Int {
  let slope = ( base + slope1 ) * 100
  // trace string.from_int(slope)
  let ratio = utilisationRatio(borrowed, supply)
  // trace string.from_int(ratio)
  let nominator = ratio - optimal
  // trace string.from_int(nominator)
  let decimalAdjustment = nominator * 100000
  let denominator = 100 - optimal
  // trace string.from_int(denominator)
  let utilisation = decimalAdjustment / denominator
  // trace string.from_int(utilisation)
  let variableFee = utilisation * slope2
  // trace string.from_int(variableFee)
  slope + variableFee / 100
}

test slope2() {
  let base = 55
  // need to / 10 to account for the decimal
  let optimal = 70
  let slope1 = 40
  let slope2 = 300
  // need to / 10 to account for decimal
  let supply = 1000000
  let borrowed = 750000 * 100

  // we need to multiply values then divide out to get the correct % because Cardano doesnt do decimals
  // we add 1 at the end to round up to 3 decimals
  interestSlope2(base, optimal, slope1, slope2, supply, borrowed) + 2 == 59500
}

test monthlyRepayments() {
  let loanValue = 100000
  let base = 55
  // need to / 10 to account for the decimal
  let optimal = 70
  let slope1 = 40
  let slope2 = 300
  // need to / 10 to account for decimal
  let supply = 1000000
  let borrowed = 750000 * 100

  let interest =
    interestSlope2(base, optimal, slope1, slope2, supply, borrowed) + 1

  let totalInterest = loanValue * interest / 100000

  let payment = totalInterest / 12

  payment == 4958
}

pub fn interestPayment(timestamp: Int, loan: Int, interest: Int) {
  let timeframe = 31556926 / timestamp
  loan * interest / timeframe
}

test interestTimeframe() {
  let loan = 1000
  let timestamp = 2629743
  let interest = 8500

  // calc is 0.7% p month 
  interestPayment(timestamp, loan, interest) == 708333
}

test interestValue() {
  let loan = 2000000
  let timestamp = 2629743
  let interest = 8500

  interestPayment(timestamp, loan, interest) == 1416666666
}
