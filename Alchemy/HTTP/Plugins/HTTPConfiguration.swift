import HummingbirdCore

public struct HTTPConfiguration: Plugin {
    static let defaultHost = "127.0.0.1"
    static let defaultPort = 3000
    
    /// The default hashing algorithm.
    public let defaultHashAlgorithm: HashAlgorithm
    /// Maximum upload size allowed.
    public let maxUploadSize: Int
    /// Maximum size of data in flight while streaming request payloads before back pressure is applied.
    public let maxStreamingBufferSize: Int
    /// Defines the maximum length for the queue of pending connections
    public let backlog: Int
    /// Disables the Nagle algorithm for send coalescing.
    public let tcpNoDelay: Bool
    /// Pipelining ensures that only one http request is processed at one time.
    public let withPipeliningAssistance: Bool
    /// Timeout when reading a request.
    public let readTimeout: TimeAmount
    /// Timeout when writing a response.
    public let writeTimeout: TimeAmount

    public init(
        defaultHashAlgorithm: HashAlgorithm = .bcrypt,
        maxUploadSize: Int = 2 * 1024 * 1024,
        maxStreamingBufferSize: Int = 1 * 1024 * 1024,
        backlog: Int = 256,
        tcpNoDelay: Bool = true,
        withPipeliningAssistance: Bool = true,
        readTimeout: TimeAmount = .seconds(30),
        writeTimeout: TimeAmount = .minutes(3)
    ) {
        self.defaultHashAlgorithm = defaultHashAlgorithm
        self.maxUploadSize = maxUploadSize
        self.maxStreamingBufferSize = maxStreamingBufferSize
        self.backlog = backlog
        self.tcpNoDelay = tcpNoDelay
        self.withPipeliningAssistance = withPipeliningAssistance
        self.readTimeout = readTimeout
        self.writeTimeout = writeTimeout
    }
    
    public func registerServices(in app: Application) {
        
        // 0. Register Server
        
        app.container.register { HBHTTPServer(group: $0.require(), configuration: hummingbirdConfiguration()) }.singleton()
        
        // 1. Register Router
        
        app.container.register(HTTPRouter()).singleton()
        app.container.register { $0.require() as HTTPRouter as Router }
        
        // 2. Register Handler
        
        app.container.register { HTTPHandler(maxUploadSize: maxUploadSize, router: $0.require() as HTTPRouter) }.singleton()
        app.container.register { $0.require() as HTTPHandler as RequestHandler }
        
        // 3. Register Client
        
        app.container.register(Client()).singleton()
        
        // 4. Register Hasher

        app.container.register(Hasher(algorithm: defaultHashAlgorithm)).singleton()
    }

    public func shutdownServices(in app: Application) async throws {
        try app.container.resolve(Client.self)?.shutdown()
        try await app.container.resolve(HBHTTPServer.self)?.stop().get()
    }

    private func hummingbirdConfiguration() -> HBHTTPServer.Configuration {
        HBHTTPServer.Configuration(
            address: {
                if let socket = CommandLine.value(for: "--socket") {
                    return .unixDomainSocket(path: socket)
                } else {
                    let host = CommandLine.value(for: "--host") ?? HTTPConfiguration.defaultHost
                    let port = (CommandLine.value(for: "--port").map { Int($0) } ?? nil) ?? HTTPConfiguration.defaultPort
                    return .hostname(host, port: port)
                }
            }(),
            maxUploadSize: maxUploadSize,
            maxStreamingBufferSize: maxStreamingBufferSize,
            backlog: backlog,
            tcpNoDelay: tcpNoDelay,
            withPipeliningAssistance: withPipeliningAssistance,
            idleTimeoutConfiguration: HBHTTPServer.IdleStateHandlerConfiguration(
                readTimeout: readTimeout,
                writeTimeout: writeTimeout
            )
        )
    }
}

extension Application {
    public var server: HBHTTPServer {
        Container.require()
    }
}
