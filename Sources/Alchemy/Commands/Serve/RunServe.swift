import ArgumentParser
import NIO
import NIOSSL
import NIOHTTP1
import NIOHTTP2
import Lifecycle

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
    
    @IgnoreDecoding
    private var server: Server?
    
    // MARK: Command

    func run() throws {
        @Inject var lifecycle: ServiceLifecycle
        
        if migrate {
            lifecycle.register(
                label: "Migrate",
                start: .eventLoopFuture {
                    Loop.group.next().wrapAsync {
                        try await Database.default.migrate()
                    }
                },
                shutdown: .none
            )
        }
        
        registerToLifecycle()
        
        if schedule {
            lifecycle.registerScheduler()
        }
        
        if workers > 0 {
            lifecycle.registerWorkers(workers, on: .default)
        }
    }
    
    func start() async throws {
        let server = Server()
        if let unixSocket = unixSocket {
            try await server.listen(on: .unix(path: unixSocket))
        } else {
            try await server.listen(on: .ip(host: host, port: port))
        }
        
        self.server = server
    }
    
    func shutdown() async throws {
        try await server?.shutdown()
    }
}

@propertyWrapper
private struct IgnoreDecoding<T>: Decodable {
    var wrappedValue: T?
    
    init(from decoder: Decoder) throws {
        wrappedValue = nil
    }
    
    init() {
        wrappedValue = nil
    }
}
