@testable import Alchemy

extension MemoryCache {
    public func expectSet<L: LosslessStringConvertible & Equatable>(_ key: String, _ val: L? = nil) {
        #expect(has(key))
        if let val = val {
            #expect(throws: Never.self) { let _: L? = try self.get(key) }
            #expect(try! get(key) == val)
        }
    }
    
    public func expectNotSet(_ key: String) {
        #expect(!has(key))
    }
    
    public func expectEmpty() {
        #expect(data.isEmpty)
    }
}
