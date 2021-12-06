import ArgumentParser
import NIO
import NIOSSL
import NIOHTTP1
import NIOHTTP2
import Lifecycle
import Hummingbird

/// Command to serve on launched. This is a subcommand of `Launch`.
/// The app will route with the singleton `HTTPRouter`.
final class RunServe: Command {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "serve")
    }
    
    static var shutdownAfterRun: Bool = false
    static var logStartAndFinish: Bool = false
    
    /// The host to serve at. Defaults to `127.0.0.1`.
    @Option var host = "127.0.0.1"
    
    /// The port to serve at. Defaults to `3000`.
    @Option var port = 3000
    
    /// The unix socket to serve at. If this is provided, the host and
    /// port will be ignored.
    @Option var unixSocket: String?
    
    /// The number of Queue workers that should be kicked off in
    /// this process. Defaults to `0`.
    @Option var workers: Int = 0
    
    /// Should the scheduler run in process, scheduling any recurring
    /// work. Defaults to `false`.
    @Flag var schedule: Bool = false
    
    /// Should migrations be run before booting. Defaults to `false`.
    @Flag var migrate: Bool = false
    
    init() {}
    init(host: String = "127.0.0.1", port: Int = 3000, workers: Int = 0, schedule: Bool = false, migrate: Bool = false) {
        self.host = host
        self.port = port
        self.unixSocket = nil
        self.workers = workers
        self.schedule = schedule
        self.migrate = migrate
    }
    
    // MARK: Command

    func run() throws {
        @Inject var lifecycle: ServiceLifecycle
        
        if migrate {
            lifecycle.register(
                label: "Migrate",
                start: .eventLoopFuture {
                    Loop.group.next()
                        .asyncSubmit(Database.default.migrate)
                },
                shutdown: .none
            )
        }
        
        let config: HBApplication.Configuration
        if let unixSocket = unixSocket {
            config = .init(address: .unixDomainSocket(path: unixSocket), logLevel: .notice)
        } else {
            config = .init(address: .hostname(host, port: port), logLevel: .notice)
        }
        
        let server = HBApplication(configuration: config, eventLoopGroupProvider: .shared(Loop.group))
        server.router = Router.default
        Container.register(singleton: server)
        
        registerWithLifecycle()
        
        if schedule {
            lifecycle.registerScheduler()
        }
        
        if workers > 0 {
            lifecycle.registerWorkers(workers, on: .default)
        }
    }
    
    func start() throws {
        @Inject var server: HBApplication
        
        try server.start()
        if let unixSocket = unixSocket {
            Log.info("[Server] listening on \(unixSocket).")
        } else {
            Log.info("[Server] listening on \(host):\(port).")
        }
    }
    
    func shutdown() throws {
        @Inject var server: HBApplication
        
        let promise = server.eventLoopGroup.next().makePromise(of: Void.self)
        server.lifecycle.shutdown { error in
            if let error = error {
                promise.fail(error)
            } else {
                promise.succeed(())
            }
        }
        
        try promise.futureResult.wait()
    }
}

extension Router: HBRouter {
    public func respond(to request: HBRequest) -> EventLoopFuture<HBResponse> {
        request.eventLoop
            .asyncSubmit { await self.handle(request: Request(hbRequest: request)) }
            .map { HBResponse(status: $0.status, headers: $0.headers, body: $0.hbResponseBody) }
    }
    
    public func add(_ path: String, method: HTTPMethod, responder: HBResponder) { /* using custom router funcs */ }
}

extension Response {
    var hbResponseBody: HBResponseBody {
        switch body {
        case .buffer(let buffer):
            return .byteBuffer(buffer)
        case .stream(let stream):
            let proxy = HBStreamerProxy(stream: stream, eventLoop: Loop.current)
            return .stream(proxy)
        case .none:
            return .empty
        }
    }
}

// Streams can be written to and read.
// Streams can be written to all at once or one at a time.
// Streams can be read all at once or one at a time.
final class Stream<Element>: AsyncSequence {
    private let eventLoop: EventLoop
    private var readPromise: EventLoopPromise<Void>
    private var writePromise: EventLoopPromise<Element>
    private let onFirstRead: ((Stream<Element>) -> Void)?
    private var didFirstRead: Bool
    
    init(eventLoop: EventLoop, onFirstRead: ((Stream<Element>) -> Void)? = nil) {
        self.eventLoop = eventLoop
        self.readPromise = eventLoop.makePromise(of: Void.self)
        self.writePromise = eventLoop.makePromise(of: Element.self)
        self.onFirstRead = onFirstRead
        self.didFirstRead = false
    }
    
    func _write(_ chunk: Element) -> EventLoopFuture<Void> {
        // Write the next one.
        writePromise.succeed(chunk)
        defer { writePromise = eventLoop.makePromise(of: Element.self) }
        // Wait until its read.
        return readPromise.futureResult
    }
    
    func _read(on eventLoop: EventLoop) -> EventLoopFuture<Element> {
        eventLoop
            .submit {
                if !self.didFirstRead {
                    self.didFirstRead = true
                    self.onFirstRead?(self)
                }
            }
            .flatMap {
                // Notify it's read.
                defer {
                    self.readPromise.succeed(())
                    self.readPromise = eventLoop.makePromise(of: Void.self)
                }
                
                // Read the next one.
                return self.writePromise.futureResult
            }
    }
    
    // MARK: - AsycIterator
    
    struct AsyncIterator: AsyncIteratorProtocol {
        let stream: Stream
        let eventLoop: EventLoop
        
        mutating func next() async throws -> Element? {
            try await stream._read(on: eventLoop).get()
        }
    }
    
    __consuming func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(stream: self, eventLoop: eventLoop)
    }
}

final class HBStreamerProxy: HBResponseBodyStreamer {
    let stream: ByteStream
    let streamer: Stream<HBStreamerOutput>
    
    init(stream: ByteStream, eventLoop: EventLoop) {
        self.stream = stream
        self.streamer = Stream<HBStreamerOutput>(eventLoop: eventLoop) { streamer in
            Task {
                try await stream.read { buffer in
                    try await streamer._write(.byteBuffer(buffer)).get()
                }
                
                try await streamer._write(.end).get()
            }
        }
    }
    
    func read(on eventLoop: EventLoop) -> EventLoopFuture<HBStreamerOutput> {
        streamer._read(on: eventLoop)
    }
}
