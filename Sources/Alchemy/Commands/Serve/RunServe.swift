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
                        .wrapAsync(Database.default.migrate)
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
    public func add(_ path: String, method: HTTPMethod, responder: HBResponder) {
        // ignore
    }
    
    public func respond(to request: HBRequest) -> EventLoopFuture<HBResponse> {
        let req = Request(
            head: .init(
                version: request.version,
                method: request.method,
                uri: request.uri.string
            ),
            bodyBuffer: request.body.buffer,
            remoteAddress: request.remoteAddress
        )
        
        return request.eventLoop
            .wrapAsync { await self.handle(request: req) }
            .map { res in
                let body: HBResponseBody = res.content.map { .byteBuffer($0.buffer) } ?? .empty
                return HBResponse(status: res.status, headers: res.headers, body: body)
            }
    }
}
