import AsyncHTTPClient
import HummingbirdCore

/// A collection of bytes that is either a single buffer or a stream of buffers.
public enum Bytes: ExpressibleByStringLiteral {
    /// The default decoder for reading content from an incoming request.
    public static var defaultDecoder: HTTPDecoder = .json
    /// The default encoder for writing content to an outgoing response.
    public static var defaultEncoder: HTTPEncoder = .json
    
    case buffer(ByteBuffer)
    case stream(AsyncStream<ByteBuffer>)

    public var buffer: ByteBuffer {
        guard case .buffer(let buffer) = self else {
            preconditionFailure("Can't synchronously access data from streaming body, try `collect()` instead.")
        }

        return buffer
    }
    
    public var stream: AsyncStream<ByteBuffer> {
        switch self {
        case .stream(let stream):
            return stream
        case .buffer(let buffer):
            return AsyncStream { buffer }
        }
    }
    
    public var length: Int? {
        guard case .buffer(let buffer) = self else {
            return nil
        }

        return buffer.writerIndex
    }

    public var string: String {
        String(buffer: buffer)
    }

    public var data: Data {
        Data(buffer: buffer)
    }

    /// Returns the contents of the entire buffer or stream as a single buffer.
    public func collect() async throws -> ByteBuffer {
        switch self {
        case .buffer(let byteBuffer):
            return byteBuffer
        case .stream(let byteStream):
            var collection = ByteBuffer()
            for try await var chunk in byteStream {
                collection.writeBuffer(&chunk)
            }

            return collection
        }
    }

    // MARK: ExpressibleByStringLiteral

    public init(stringLiteral value: String) {
        self = .string(value)
    }

    // MARK: Convenience Functions for Creating `Bytes`

    public static func data(_ data: Data) -> Bytes {
        .buffer(ByteBuffer(data: data))
    }

    public static func string(_ string: String) -> Bytes {
        .buffer(ByteBuffer(string: string))
    }

    public static func encode<E: Encodable>(_ value: E, using encoder: HTTPEncoder = Bytes.defaultEncoder) throws -> Bytes {
        let (buffer, _) = try encoder.encodeBody(value)
        return .buffer(buffer)
    }

    public static func stream<AS: AsyncSequence>(sequence: AS) -> Bytes where AS.Element == ByteBuffer {
        .stream(
            AsyncStream<ByteBuffer> { continuation in
                Task {
                    for try await chunk in sequence {
                        continuation.yield(chunk)
                    }

                    continuation.finish()
                }
            }
        )
    }
}
