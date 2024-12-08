import Foundation
import Testing

struct UUIDLosslessStringConvertibleTests {
    @Test func validUUID() {
        let uuid = UUID()
        #expect(UUID(uuid.uuidString) == uuid)
    }

    @Test func invalidUUID() {
        #expect(UUID("foo") == nil)
    }
}
