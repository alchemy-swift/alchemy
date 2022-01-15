// Used for verifying expectations (XCTExpectation isn't as needed since things are async now).
actor Expect {
    var one = false, two = false, three = false, four = false, five = false, six = false
    
    func signalOne() async { one = true }
    func signalTwo() async { two = true }
    func signalThree() async { three = true }
    func signalFour() async { four = true }
    func signalFive() async { five = true }
    func signalSix() async { six = true }
}
