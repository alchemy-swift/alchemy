import NIO
import NIOSSL
import NIOHTTP1
import NIOHTTP2
import HummingbirdCore

let kDefaultHost = "127.0.0.1"
let kDefaultPort = 3000

struct ServeCommand: Command {
    static let name = "serve"
    static var runUntilStopped: Bool = true
    
    /// The host to serve at. Defaults to `127.0.0.1`.
    @Option var host = kDefaultHost

    /// The port to serve at. Defaults to `3000`.
    @Option var port = kDefaultPort

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
            app.schedule(on: Schedule)
            Schedule.start()
        }

        for _ in 0..<workers {
            Q.startWorker()
        }

        let responder = HTTPResponder(logResponses: !quiet)
        try await app.server.start(responder: responder).get()

        let address = app.server.configuration.address
        if let unixSocket = address.unixDomainSocketPath {
            Log.info("Server running on \(unixSocket).")
        } else if let host = address.host, let port = address.port {
            let link = "[http://\(host):\(port)]".bold
            Log.info("Server running on \(link).")
        }

        let stop = Env.isXcode ? "Cmd+Period" : "Ctrl+C"
        Log.comment("Press \(stop) to stop the server".yellow)
        if !Env.isXcode {
            print()
        }
    }
}

private struct HTTPResponder: HBHTTPResponder {
    @Inject var handler: RequestHandler

    let logResponses: Bool

    func respond(to request: HBHTTPRequest, context: ChannelHandlerContext, onComplete: @escaping (Result<HBHTTPResponse, Error>) -> Void) {
        let startedAt = Date()
        let req = Request(method: request.head.method,
                          uri: request.head.uri,
                          headers: request.head.headers,
                          version: request.head.version,
                          body: request.body.byteContent(on: context.eventLoop),
                          localAddress: context.localAddress,
                          remoteAddress: context.remoteAddress,
                          eventLoop: context.eventLoop)
        context.eventLoop
            .asyncSubmit {
                let res = await handler.handle(request: req)
                if logResponses {
                    logResponse(req: req, res: res, startedAt: startedAt)
                }

                let head = HTTPResponseHead(version: req.version, status: res.status, headers: res.headers)
                return HBHTTPResponse(head: head, body: res.body.hbResponseBody)
            }
            .whenComplete(onComplete)
    }

    private func logResponse(req: Request, res: Response, startedAt: Date) {
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
        let right = "\(startedAt.elapsedString) \(res.status.code)"
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

extension HBHTTPError: ResponseConvertible {
    public func response() -> Response {
        Response(status: status, headers: headers, body: body.map { .string($0) })
    }
}

extension HBRequestBody {
    fileprivate func byteContent(on eventLoop: EventLoop) -> Bytes? {
        switch self {
        case .byteBuffer(let bytes):
            return bytes.map { .buffer($0) }
        case .stream(let streamer):
            return .stream(ByteStream { writer in
                try await streamer.consumeAll(on: eventLoop) { buffer in
                    eventLoop.asyncSubmit {
                        try await writer.write(buffer)
                    }
                }
                .get()
            })
        }
    }
}

extension Bytes? {
    private struct StreamerProxy: HBResponseBodyStreamer, @unchecked Sendable {
        let stream: ByteStream

        func read(on eventLoop: EventLoop) -> EventLoopFuture<HBStreamerOutput> {
            stream._read(on: eventLoop).map { $0.map { .byteBuffer($0) } ?? .end }
        }
    }

    fileprivate var hbResponseBody: HBResponseBody {
        switch self {
        case .buffer(let buffer):
            return .byteBuffer(buffer)
        case .stream(let stream):
            return .stream(StreamerProxy(stream: stream))
        case .none:
            return .empty
        }
    }
}
