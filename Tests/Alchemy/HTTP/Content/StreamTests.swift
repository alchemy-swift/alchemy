@testable
import Alchemy
import AlchemyTest

final class StreamTests: TestCase<TestApp> {
    func testUnusedDoesntCrash() throws {
        _ = ByteStream(eventLoop: Loop.current)
    }
}
