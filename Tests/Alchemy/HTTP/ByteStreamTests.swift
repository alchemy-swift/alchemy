@testable
import Alchemy
import AlchemyTest

final class ByteStreamTests: XCTestCase {
    func testUnusedDoesntCrash() throws {
        _ = ByteStream(eventLoop: EmbeddedEventLoop())
    }
}
