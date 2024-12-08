import Hummingbird
import NIOCore

struct ServeCommand: Command {
    static let name = "serve"

    /// The host to serve at. Defaults to `127.0.0.1`.
    @Option var host = "127.0.0.1"

    /// The port to serve at. Defaults to `3000`.
    @Option var port = 3000

    /// The unix socket to serve at. If this is provided, the host and
    /// port will be ignored.
    @Option var socket: String?

    /// The number of Queue workers that should be started in this process.
    /// Defaults to `0`.
    @Option var workers: Int = 0

    /// Max pending connections. Defaults to `256`.
    @Option var backlog = 256

    /// Server name to return in "server" header. Defaults to `nil`.
    @Option var name: String?

    /// Should the scheduler run in process, scheduling any recurring
    /// work. Defaults to `false`.
    @Flag var schedule: Bool = false
    
    /// Should migrations be run before booting.
    @Flag var migrate: Bool = false

    /// If enabled, handled requests won't be logged.
    @Flag var quiet: Bool = false

    /// Disables the server from bind to an address already in use.
    @Flag var disableReuse: Bool = false

    /// The address to bind the server too.
    private var address: BindAddress {
        if let socket {
            .unixDomainSocket(path: socket)
        } else {
            .hostname(host, port: port)
        }
    }

    // MARK: Command

    func run() async throws {

        // 0. migrate if needed

        if migrate {
            try await DB.migrate()
            Log.comment("")
        }

        // 1. start scheduler if needed

        if schedule {
            Schedule.start()
        }

        // 2. start any workers

        for _ in 0..<workers {
            Q.startWorker()
        }

        // 3. add hummingbird application

        Life.addService(
            Hummingbird.Application(
                responder: Responder(handler: Handle, logResponses: !quiet),
                server: Main.server,
                configuration: ApplicationConfiguration(
                    address: address,
                    serverName: name,
                    backlog: backlog,
                    reuseAddress: !disableReuse
                ),
                onServerRunning: onServerRunning,
                eventLoopGroupProvider: .shared(LoopGroup),
                logger: Log
            )
        )

        // 4. start services

        try await Life.runServices()
    }

    @Sendable
    private func onServerRunning(channel: Channel) {
        if let socket {
            Log.info("Server running on \(socket).")
        } else {
            let link = "[http://\(host):\(port)]".bold
            Log.info("Server running on \(link).")
        }

        if Container.isXcode {
            Log.comment("Press Cmd+Period to stop the server")
        } else {
            Log.comment("Press Ctrl+C to stop the server".yellow)
            print()
        }
    }
}
