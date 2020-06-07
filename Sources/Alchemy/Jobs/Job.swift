import NIO

public protocol Job {
    func run() -> EventLoopFuture<Void>
}
