import NIO

public protocol RequestContext {
    var eventLoop: EventLoop { get }
    var remoteAddress: SocketAddress? { get }
    var allocator: ByteBufferAllocator { get }
}
