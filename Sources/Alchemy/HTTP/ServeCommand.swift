import ArgumentParser
import NIO
import NIOSSL
import NIOHTTP1
import NIOHTTP2
import Lifecycle
import HummingbirdCore

let kDefaultHost = "127.0.0.1"
let kDefaultPort = 3000

/// Command to serve on launched. This is a subcommand of `Launch`.
/// The app will route with the singleton `HTTPRouter`.
struct ServeCommand: Command {
    static let name = "serve"
    static var shutdownAfterRun: Bool = false
    
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
    init(host: String = "127.0.0.1", port: Int = 3000, workers: Int = 0, schedule: Bool = false, migrate: Bool = false) {
        self.host = host
        self.port = port
        self.socket = nil
        self.workers = workers
        self.schedule = schedule
        self.migrate = migrate
    }

    // MARK: Command

    func run() async throws {
        @Inject var app: Application
        if migrate {
            try await DB.migrate()
        }

        if schedule {
            Schedule.start()
        }

        for _ in 0..<workers {
            Q.startWorker()
        }

        if !quiet {
            Routes.didHandle(logResponse)
        }

        let responder = RouterResponder(router: Routes)
        try await app.server.start(responder: responder).get()

        if let unixSocket = socket {
            Log.info("Server running on \(unixSocket).")
        } else {
            let link = "[http://\(host):\(port)]".bold
            Log.info("Server running on \(link).")
        }

        let stop = Env.isXcode ? "Cmd+Period" : "Ctrl+C"
        Log.comment("Press \(stop) to stop the server".yellow)
        if !Env.isXcode {
            print()
        }
    }

    private func logResponse(req: Request, res: Response) {
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

private struct RouterResponder: HBHTTPResponder {
    let router: Router

    func respond(to request: HBHTTPRequest, context: ChannelHandlerContext, onComplete: @escaping (Result<HBHTTPResponse, Error>) -> Void) {
        let req = Request(head: request.head, body: request.body.byteContent(on: context.eventLoop), context: context)
        context.eventLoop
            .asyncSubmit {
                let res = await router.handle(request: req)
                let head = HTTPResponseHead(version: req.version, status: res.status, headers: res.headers)
                return HBHTTPResponse(head: head, body: res.body.hbResponseBody)
            }
            .whenComplete(onComplete)
    }
}

extension ChannelHandlerContext: RequestContext {
    public var allocator: ByteBufferAllocator {
        channel.allocator
    }
}

extension HBRequestBody {
    func byteContent(on eventLoop: EventLoop) -> ByteContent? {
        switch self {
        case .byteBuffer(let bytes):
            return bytes.map { .buffer($0) }
        case .stream(let streamer):
            return .stream(.new { reader in
                try await streamer
                    .consumeAll(on: eventLoop) { buffer in
                        eventLoop.asyncSubmit {
                            try await reader.write(buffer)
                        }
                    }
                    .get()
            })
        }
    }
}

extension ByteContent? {
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

struct StreamerProxy: HBResponseBodyStreamer {
    let stream: ByteStream

    func read(on eventLoop: EventLoop) -> EventLoopFuture<HBStreamerOutput> {
        stream._read(on: eventLoop).map { $0.map { .byteBuffer($0) } ?? .end }
    }
}

extension ByteStream: @unchecked Sendable {}

extension HBHTTPError: ResponseConvertible {
    public func response() -> Response {
        Response(status: status, headers: headers, body: body.map { .string($0) })
    }
}
