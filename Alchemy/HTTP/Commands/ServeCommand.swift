import NIO
import NIOSSL
import NIOHTTP1
import NIOHTTP2
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

        let responder = HTTPResponder(logResponses: !quiet)
        try await app.server.start(responder: responder).get()

        let address = app.server.configuration.address
        if let unixSocket = address.unixDomainSocketPath {
            Log.info("Server running on \(unixSocket).")
        } else if let host = address.host, let port = address.port {
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

extension String {
    /// String with black text.
    public var black: String { Env.isXcode ? self : applyingColor(.black) }
    /// String with red text.
    public var red: String { Env.isXcode ? self : applyingColor(.red)   }
    /// String with green text.
    public var green: String { Env.isXcode ? self : applyingColor(.green) }
    /// String with yellow text.
    public var yellow: String { Env.isXcode ? self : applyingColor(.yellow) }
    /// String with blue text.
    public var blue: String { Env.isXcode ? self : applyingColor(.blue) }
    /// String with magenta text.
    public var magenta: String { Env.isXcode ? self : applyingColor(.magenta) }
    /// String with cyan text.
    public var cyan: String { Env.isXcode ? self : applyingColor(.cyan) }
    /// String with white text.
    public var white: String { Env.isXcode ? self : applyingColor(.white) }
    /// String with light black text. Generally speaking, it means dark grey in some consoles.
    public var lightBlack: String { Env.isXcode ? self : applyingColor(.lightBlack) }
    /// String with light red text.
    public var lightRed: String { Env.isXcode ? self : applyingColor(.lightRed) }
    /// String with light green text.
    public var lightGreen: String { Env.isXcode ? self : applyingColor(.lightGreen) }
    /// String with light yellow text.
    public var lightYellow: String { Env.isXcode ? self : applyingColor(.lightYellow) }
    /// String with light blue text.
    public var lightBlue: String { Env.isXcode ? self : applyingColor(.lightBlue) }
    /// String with light magenta text.
    public var lightMagenta: String { Env.isXcode ? self : applyingColor(.lightMagenta) }
    /// String with light cyan text.
    public var lightCyan: String { Env.isXcode ? self : applyingColor(.lightCyan) }
    /// String with light white text. Generally speaking, it means light grey in some consoles.
    public var lightWhite: String { Env.isXcode ? self : applyingColor(.lightWhite) }
}

extension String {
    /// String with bold style.
    public var bold: String { Env.isXcode ? self : applyingStyle(.bold) }
    /// String with dim style. This is not widely supported in all terminals. Use it carefully.
    public var dim: String { Env.isXcode ? self : applyingStyle(.dim) }
    /// String with italic style. This depends on whether an italic existing for the font family of terminals.
    public var italic: String { Env.isXcode ? self : applyingStyle(.italic) }
    /// String with underline style.
    public var underline: String { Env.isXcode ? self : applyingStyle(.underline) }
    /// String with blink style. This is not widely supported in all terminals, or need additional setting. Use it carefully.
    public var blink: String { Env.isXcode ? self : applyingStyle(.blink) }
    /// String with text color and background color swapped.
    public var swap: String { Env.isXcode ? self : applyingStyle(.swap) }
}
