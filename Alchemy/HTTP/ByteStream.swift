import HummingbirdCore
import NIOCore

public struct StreamWriter: AsyncSequence {
    public typealias Element = ByteBuffer

    public struct AsyncIterator: AsyncIteratorProtocol {
        mutating public func next() async throws -> ByteBuffer? {
            fatalError()
        }
    }

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator()
    }

    public func write(_ chunk: ByteBuffer) async throws {
        fatalError()
    }

    public func finish() {
        fatalError()
    }

    public func write(_ string: String) async throws {
        fatalError()
    }
}

/// A stream of bytes, that are delivered in sequential `ByteBuffer`s.
//public final class ByteStream: AsyncSequence {
//    public struct Writer {
//        fileprivate let stream: ByteStream
//
//        public func write(_ chunk: ByteBuffer) async throws {
//            try await stream._write(chunk: chunk).get()
//        }
//
//        public func write(_ string: String) async throws {
//            try await stream._write(chunk: ByteBuffer(string: string)).get()
//        }
//    }
//
//    public struct AsyncIterator: AsyncIteratorProtocol {
//        let stream: ByteStream
//        let eventLoop: EventLoop
//
//        mutating public func next() async throws -> ByteBuffer? {
//            try await stream._read(on: eventLoop).get()
//        }
//    }
//
//    public typealias Element = ByteBuffer
//    public typealias Streamer = (Writer) async throws -> Void
//
//    private let eventLoop: EventLoop
//    private let onFirstRead: ((ByteStream) -> Void)?
//    private var didFirstRead: Bool
//    private var _streamer: HBByteBufferStreamer?
//
//    public convenience init(streamer: @escaping Streamer) {
//        self.init(eventLoop: Loop) { stream in
//            Task {
//                do {
//                    try await streamer(Writer(stream: stream))
//                    try await stream._write(chunk: nil).get()
//                } catch {
//                    stream._write(error: error)
//                }
//            }
//        }
//    }
//
//    init(eventLoop: EventLoop, onFirstRead: ((ByteStream) -> Void)? = nil) {
//        self.eventLoop = eventLoop
//        self.onFirstRead = onFirstRead
//        self.didFirstRead = false
//    }
//
//    public func makeAsyncIterator() -> AsyncIterator {
//        AsyncIterator(stream: self, eventLoop: eventLoop)
//    }
//
//    public func readAll(chunkHandler: (ByteBuffer) async throws -> Void) async throws {
//        for try await chunk in self {
//            try await chunkHandler(chunk)
//        }
//    }
//
//    public func _read(on eventLoop: EventLoop) -> EventLoopFuture<ByteBuffer?> {
//        createStreamerIfNotExists()
//            .flatMap {
//                if !self.didFirstRead {
//                    self.didFirstRead = true
//                    self.onFirstRead?(self)
//                }
//
//                return $0.consume(on: eventLoop).map { output in
//                    switch output {
//                    case .byteBuffer(let buffer):
//                        return buffer
//                    case .end:
//                        return nil
//                    }
//                }
//            }
//            .hop(to: eventLoop)
//    }
//
//    func _write(chunk: ByteBuffer?) -> EventLoopFuture<Void> {
//        createStreamerIfNotExists()
//            .flatMap {
//                if let chunk = chunk {
//                    return $0.feed(buffer: chunk)
//                } else {
//                    $0.feed(.end)
//                    return self.eventLoop.makeSucceededVoidFuture()
//                }
//            }
//    }
//
//    private func createStreamerIfNotExists() -> EventLoopFuture<HBByteBufferStreamer> {
//        eventLoop.submit {
//            guard let _streamer = self._streamer else {
//                /// Don't give a max size to the underlying streamer; that will be handled elsewhere.
//                let created = HBByteBufferStreamer(eventLoop: self.eventLoop, maxSize: .max, maxStreamingBufferSize: nil)
//                self._streamer = created
//                return created
//            }
//
//            return _streamer
//        }
//    }
//
//    private func _write(error: Error) {
//        _ = createStreamerIfNotExists().map { $0.feed(.error(error)) }
//    }
//}
