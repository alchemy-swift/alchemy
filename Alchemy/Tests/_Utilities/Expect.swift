// Used for verifying expectations (XCTExpectation isn't as needed since things are async now).
struct Expect {
    var one = false, two = false, three = false, four = false, five = false, six = false
    
    mutating func signalOne() { one = true }
    mutating func signalTwo() { two = true }
    mutating func signalThree() { three = true }
    mutating func signalFour() { four = true }
    mutating func signalFive() { five = true }
    mutating func signalSix() { six = true }
}
