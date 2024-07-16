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

        try await buildHummingbirdApplication().run()
    }

    private func buildHummingbirdApplication() -> Hummingbird.Application<Responder> {
        let address: BindAddress = if let socket {
            .unixDomainSocket(path: socket)
        } else {
            .hostname(host, port: port)
        }
        return .init(
            responder: Responder(
                logResponses: !quiet
            ),
            server: Container.require(Application.self).server,
            configuration: ApplicationConfiguration(
                address: address,
                serverName: nil,
                backlog: 256,
                reuseAddress: false
            ),
            onServerRunning: onServerStart,
            eventLoopGroupProvider: .shared(LoopGroup),
            logger: Log
        )
    }

    @Sendable private func onServerStart(channel: Channel) async {
        if let unixSocket = socket {
            Log.info("Server running on \(unixSocket).")
        } else {
            let link = "[http://\(host):\(port)]".bold
            Log.info("Server running on \(link).")
        }

        if Env.isXcode {
            Log.comment("Press Cmd+Period to stop the server")
        } else {
            Log.comment("Press Ctrl+C to stop the server".yellow)
            print()
        }
    }
}
