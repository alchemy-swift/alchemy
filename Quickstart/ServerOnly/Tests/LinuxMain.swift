import XCTest

import ServerTests

var tests = [XCTestCaseEntry]()
tests += ServerTests.allTests()
XCTMain(tests)
