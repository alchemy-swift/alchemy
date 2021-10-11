@testable import Alchemy
import XCTest

extension MemoryCache {
    func assertSet<C: CacheAllowed & Equatable>(_ key: String, _ val: C? = nil) {
        XCTAssertTrue(has(key))
        if let val = val {
            XCTAssertNoThrow(try {
                XCTAssertEqual(try get(key), val)
            }())
        }
    }
    
    func assertNotSet(_ key: String) {
        XCTAssertFalse(has(key))
    }
    
    func assertEmpty() {
        XCTAssertTrue(data.isEmpty)
    }
}
