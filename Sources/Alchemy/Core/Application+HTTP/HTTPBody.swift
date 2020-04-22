import NIO
import Foundation
import NIOHTTP1

/// The contents of the request or response. The type of information can be read from the request/response's HTTP headers
public struct HTTPBody: ExpressibleByStringLiteral {
    /// Used to create new ByteBuffers
    private static let allocator = ByteBufferAllocator()
    
    /// The binary data in this body
    let buffer: ByteBuffer
    
    /// The mime type of the data stored in this HTTPBody
    /// Used to set the `content-type` header when sending back a response
    public let mimeType: String?
    
    /// Creates a new body from a binary `NIO.ByteBuffer`
    public init(buffer: ByteBuffer, mimeType: String? = nil) {
        self.buffer = buffer
        self.mimeType = mimeType
    }
    
    /// Creates a new text/plain body containing the text
    public init(text: String) {
        var buffer = HTTPBody.allocator.buffer(capacity: text.utf8.count)
        buffer.writeString(text)
        self.buffer = buffer
        self.mimeType = "text/plain"
    }
    
    /// Creates a new body from a binary `Foundation.Data`
    public init(data: Data, mimeType: String? = nil) {
        var buffer = HTTPBody.allocator.buffer(capacity: data.count)
        buffer.writeBytes(data)
        self.buffer = buffer
        self.mimeType = mimeType
    }
  
    /// Encodes an object to JSON with optional pretty printing as a response
    public init<E: Encodable>(json: E, pretty: Bool = false) throws {
        let encoder = JSONEncoder()
        
        if pretty {
            encoder.outputFormatting = .prettyPrinted
        }
        
        let data = try encoder.encode(json)
        
        self.init(data: data, mimeType: "application/json")
    }

    /// The same as the `text` initializer which allows this HTTPBody to be initialized from a String literal
    public init(stringLiteral value: String) {
        self.init(text: value)
    }
    
    /// Reads the Data from this body
    public var data: Data {
        return buffer.withUnsafeReadableBytes { buffer -> Data in
            let buffer = buffer.bindMemory(to: UInt8.self)
            return Data.init(buffer: buffer)
        }
    }
    
    /// Decodes the body as JSON into the provided Decodable type
    public func decodeJSON<D: Decodable>(as type: D.Type) throws -> D {
        return try JSONDecoder().decode(type, from: data)
    }
}
