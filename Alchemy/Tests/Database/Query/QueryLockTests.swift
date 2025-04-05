@testable
import Alchemy
import AlchemyTesting

struct QueryLockTests {
    @Test func lock() {
        #expect(TestQuery("foo").lock == nil)
        #expect(TestQuery("foo").lock(for: .update).lock == SQLLock(strength: .update, option: nil))
        #expect(TestQuery("foo").lock(for: .share).lock == SQLLock(strength: .share, option: nil))
        #expect(TestQuery("foo").lock(for: .update, option: .noWait).lock == SQLLock(strength: .update, option: .noWait))
        #expect(TestQuery("foo").lock(for: .update, option: .skipLocked).lock == SQLLock(strength: .update, option: .skipLocked))
    }
}
