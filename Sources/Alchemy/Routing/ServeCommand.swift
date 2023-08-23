import ArgumentParser
import NIO
import NIOSSL
import NIOHTTP1
import NIOHTTP2
import Lifecycle
import Hummingbird

/// Command to serve on launched. This is a subcommand of `Launch`.
/// The app will route with the singleton `HTTPRouter`.
struct ServeCommand: Command {
    static let name = "serve"
    static var shutdownAfterRun: Bool = false
    
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

    /// If enabled, handled requests won't be logged.
    @Flag var quiet: Bool = false

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

    func run() async throws {
        @Inject var app: Application
        @Inject var scheduler: Scheduler

        if migrate {
            try await DB.migrate()
        }

        if schedule {
            scheduler.start()
        }

        for _ in 0..<workers {
            Q.startWorker()
        }

        var config = app.configuration.hbConfiguration
        if let unixSocket = unixSocket {
            config = config.with(address: .unixDomainSocket(path: unixSocket))
        } else {
            config = config.with(address: .hostname(host, port: port))
        }

        if !quiet {
            Routes.didHandle(commentHandled)
        }

        let server = HBApplication(configuration: config, eventLoopGroupProvider: .shared(LoopGroup))
        server.logger = Log.withLevel(.notice)
        let builder = HBRouterBuilder()
        builder.middlewares.add(Routes)
        server.router = builder
        Container.main.registerSingleton(server)
        
        try server.start()
        if let unixSocket = unixSocket {
            Log.info("Server running on \(unixSocket).")
        } else {
            let link = "[http://\(host):\(port)]".bold
            Log.info("Server running on \(link).")
        }

        let stop = Env.isXcode ? "Cmd+Period" : "Ctrl+C"
        Log.comment("Press \(stop) to stop the server\n".yellow)
    }

    private func commentHandled(req: Request, res: Response) {
        enum Formatters {
            static let date: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter
            }()
            static let time: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter
            }()
        }

        let finishedAt = Date()
        let dateString = Formatters.date.string(from: finishedAt)
        let timeString = Formatters.time.string(from: finishedAt)
        let left = "\(dateString) \(timeString) \(req.path)"
        let right = "\(req.createdAt.elapsedString) \(res.status.code)"
        let dots = Log.dots(left: left, right: right)
        let code: String = {
            switch res.status.code {
            case 200...299:
                return "\(res.status.code)".green
            case 400...499:
                return "\(res.status.code)".yellow
            case 500...599:
                return "\(res.status.code)".red
            default:
                return "\(res.status.code)".white
            }
        }()

        Log.comment("\(dateString.lightBlack) \(timeString) \(req.path) \(dots.lightBlack) \(finishedAt.elapsedString.lightBlack) \(code)")
    }
}

extension Router: HBMiddleware {
    public func apply(to request: HBRequest, next: HBResponder) -> EventLoopFuture<HBResponse> {
        request.eventLoop
            .asyncSubmit { await self.handle(request: Request(hbRequest: request)) }
            .map { HBResponse(status: $0.status, headers: $0.headers, body: $0.hbResponseBody) }
    }
}

extension Response {
    var hbResponseBody: HBResponseBody {
        switch body {
        case .buffer(let buffer):
            return .byteBuffer(buffer)
        case .stream(let stream):
            return .stream(stream)
        case .none:
            return .empty
        }
    }
}

extension ByteStream: HBResponseBodyStreamer, @unchecked Sendable {
    public func read(on eventLoop: EventLoop) -> EventLoopFuture<HBStreamerOutput> {
        _read(on: eventLoop).map { $0.map { .byteBuffer($0) } ?? .end }
    }
}

extension HBHTTPError: ResponseConvertible {
    public func response() -> Response {
        Response(status: status, headers: headers, body: body.map { .string($0) })
    }
}
