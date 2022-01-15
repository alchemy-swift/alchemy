@testable import Alchemy
import XCTest

extension MemoryCache {
    public func assertSet<L: LosslessStringConvertible & Equatable>(_ key: String, _ val: L? = nil) {
        XCTAssertTrue(has(key))
        if let val = val {
            XCTAssertNoThrow(try {
                XCTAssertEqual(try get(key), val)
            }())
        }
    }
    
    public func assertNotSet(_ key: String) {
        XCTAssertFalse(has(key))
    }
    
    public func assertEmpty() {
        XCTAssertTrue(data.isEmpty)
    }
}
