import Hummingbird
import NIOCore

struct ServeCommand: Command {
    static let name = "serve"

    /// The host to serve at. Defaults to `127.0.0.1`.
    @Option var host = HTTPConfiguration.defaultHost

    /// The port to serve at. Defaults to `3000`.
    @Option var port = HTTPConfiguration.defaultPort

    /// The unix socket to serve at. If this is provided, the host and
    /// port will be ignored.
    @Option var socket: String?

    /// The number of Queue workers that should be kicked off in
    /// this process. Defaults to `0`.
    @Option var workers: Int = 0
    
    /// Should the scheduler run in process, scheduling any recurring
    /// work. Defaults to `false`.
    @Flag var schedule: Bool = false
    
    /// Should migrations be run before booting. Defaults to `false`.
    @Flag var migrate: Bool = false

    /// If enabled, handled requests won't be logged.
    @Flag var quiet: Bool = false

    // MARK: Command

    func run() async throws {

        // 0. migrate if necessary

        if migrate {
            try await DB.migrate()
            Log.comment("")
        }

        // 1. start scheduler if necessary

        if schedule {
            Schedule.start()
        }

        // 2. start any workers

        for _ in 0..<workers {
            Q.startWorker()
        }

        // 3. start serving

        @Inject var app: Application

        app.addHTTPListener(
            address: {
                if let socket {
                    .unixDomainSocket(path: socket)
                } else {
                    .hostname(host, port: port)
                }
            }(),
            logResponses: !quiet
        )

        try await app.lifecycle.runServices()
    }
}
