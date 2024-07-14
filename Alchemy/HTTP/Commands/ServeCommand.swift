import NIO
import NIOSSL
import NIOHTTP1
import NIOHTTP2
@preconcurrency import Hummingbird
import HummingbirdCore

struct ServeCommand: Command {
    static let name = "serve"
    static var runUntilStopped: Bool = true
    
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

    init() {}
    init(host: String = "127.0.0.1", port: Int = 3000, workers: Int = 0, schedule: Bool = false, migrate: Bool = false, quiet: Bool = true) {
        self.host = host
        self.port = port
        self.socket = nil
        self.workers = workers
        self.schedule = schedule
        self.migrate = migrate
        self.quiet = true
    }

    // MARK: Command

    func run() async throws {
        @Inject var app: Application
        if migrate {
            try await DB.migrate()
            Log.comment("")
        }

        if schedule {
            Schedule.start()
        }

        for _ in 0..<workers {
            Q.startWorker()
        }

        var configuration = app.configuration
        if let socket {
            configuration.address = .unixDomainSocket(path: socket)
        } else {
            configuration.address = .hostname(host, port: port)
        }

        let responder = AlchemyResponder(logResponses: !quiet)
        let hbApplication = HBApplication(
            responder: responder,
            server: app.serverBuilder,
            configuration: configuration,
            services: [],
            onServerRunning: { channel in
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
            },
            eventLoopGroupProvider: .shared(LoopGroup)
        )

        try await hbApplication.run()
    }
}

extension Application {
    var configuration: ApplicationConfiguration {
        ApplicationConfiguration(
            address: .hostname("localhost", port: 3000),
            serverName: nil,
            backlog: 100,
            reuseAddress: false
        )
    }

    var serverBuilder: HTTPServerBuilder {
        .http1()
    }
}

public typealias HBResponse = Hummingbird.Response
public typealias HBRequest = Hummingbird.Request
public typealias HBApplication = Hummingbird.Application

public struct AlchemyContext: RequestContext {
    public var coreContext: CoreRequestContextStorage
    public let source: ApplicationRequestContextSource

    public init(source: ApplicationRequestContextSource) {
        self.coreContext = .init(source: source)
        self.source = source
    }
}

public struct AlchemyResponder: HTTPResponder {
    @Inject var handler: RequestHandler

    let logResponses: Bool

    // TODO: Consider using HB request? Is there a reason to roll your own?

    public func respond(to request: HBRequest, context: AlchemyContext) async throws -> HBResponse {
        let startedAt = Date()
        let req = Request(
            method: request.method,
            uri: request.uri.string,
            headers: request.headers,
            body: request.body.bytes(),
            localAddress: context.source.channel.localAddress,
            remoteAddress: context.source.channel.remoteAddress
        )

        let res = await handler.handle(request: req)
        if logResponses {
            logResponse(req: req, res: res, startedAt: startedAt)
        }

        return HBResponse(
            status: res.status,
            headers: res.headers,
            body: res.body.hbResponseBody
        )
    }
}

extension RequestBody {
    fileprivate func bytes() -> Bytes? {
        .stream(
            AsyncStream<ByteBuffer> { continuation in
                Task {
                    for try await buffer in self {
                        continuation.yield(buffer)
                    }

                    continuation.finish()
                }
            }
        )
    }
}

extension Bytes? {
    fileprivate var hbResponseBody: ResponseBody {
        switch self {
        case .buffer(let buffer):
            return .init(byteBuffer: buffer)
        case .stream(let stream):
            return .init(asyncSequence: stream)
        case .none:
            return .init()
        }
    }
}

// MARK: Response Logging

extension AlchemyResponder {
    fileprivate func logResponse(req: Request, res: Response, startedAt: Date) {
        enum Formatters {
            static let date: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter
            }()
            static let time: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm:ss"
                return formatter
            }()
        }

        enum Status {
            case success
            case warning
            case error
            case other
        }

        let finishedAt = Date()
        let dateString = Formatters.date.string(from: finishedAt)
        let timeString = Formatters.time.string(from: finishedAt)
        let left = "\(dateString) \(timeString) \(req.method) \(req.path)"
        let right = "\(startedAt.elapsedString) \(res.status.code)"
        let dots = Log.dots(left: left, right: right)
        let status: Status = {
            switch res.status.code {
            case 200...299:
                return .success
            case 400...499:
                return .warning
            case 500...599:
                return .error
            default:
                return .other
            }
        }()

        if Env.isXcode {
            let logString = "\(dateString.lightBlack) \(timeString) \(req.path) \(dots.lightBlack) \(finishedAt.elapsedString.lightBlack) \(res.status.code)"
            switch status {
            case .success, .other:
                Log.comment(logString)
            case .warning:
                Log.warning(logString)
            case .error:
                Log.critical(logString)
            }
        } else {
            var code = "\(res.status.code)"
            switch status {
            case .success:
                code = code.green
            case .warning:
                code = code.yellow
            case .error:
                code = code.red
            case .other:
                code = code.white
            }

            Log.comment("\(dateString.lightBlack) \(timeString) \(req.method) \(req.path) \(dots.lightBlack) \(finishedAt.elapsedString.lightBlack) \(code)")
        }
    }
}
