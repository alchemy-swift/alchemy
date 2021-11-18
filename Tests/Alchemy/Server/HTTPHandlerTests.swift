@testable
import Alchemy
import AlchemyTest
import NIO
import NIOHTTP1

final class HTTPHanderTests: XCTestCase {
    func testHandle() async throws {
        let handler = HTTPHandler(handler: { _ in Response(status: .ok) })
        let channel = EmbeddedChannel()
        try await channel.pipeline.addHandler(handler).get()
        let head = HTTPRequestHead(version: .http1_1, method: .GET, uri: "/hello")
        try channel.writeInbound(HTTPServerRequestPart.head(head))
        let buffer = ByteBuffer(string: "Hello, world!")
        try channel.writeInbound(HTTPServerRequestPart.body(buffer))
        try channel.writeInbound(HTTPServerRequestPart.end(nil))
        channel.embeddedEventLoop.run()
        
        guard case .head(let head) = try channel.readOutbound(as: HTTPServerResponsePart.self) else {
            print("no head")
            throw AlchemyTestError(message: "There was no head in the response")
        }
        
        var next = try channel.readOutbound(as: HTTPServerResponsePart.self)
        var responseBuffer = channel.allocator.buffer(capacity: 0)
        while case .body(let part) = next {
            guard case .byteBuffer(var partBuffer) = part else {
                print("not body")
                throw AlchemyTestError(message: "All body parts should be a byte buffer")
            }
            
            responseBuffer.writeBuffer(&partBuffer)
            next = try channel.readOutbound(as: HTTPServerResponsePart.self)
        }
        
        guard case .end(let end) = try channel.readOutbound(as: HTTPServerResponsePart.self) else {
            print("no end")
            throw AlchemyTestError(message: "There was no end to the response")
        }
    }
}

struct AlchemyTestError: Error {
    let message: String
}
