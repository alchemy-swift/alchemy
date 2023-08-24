extension Application {
    public typealias Configuration = ApplicationConfiguration
}

public struct ApplicationConfiguration {
    /// Application plugins.
    public let plugins: () -> [Plugin]
    /// Application commands.
    public let commands: [Command.Type]
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
        plugins: @escaping @autoclosure () -> [Plugin] = [],
        commands: [Command.Type] = [],
        maxUploadSize: Int = 2 * 1024 * 1024,
        maxStreamingBufferSize: Int = 1 * 1024 * 1024,
        backlog: Int = 256,
        tcpNoDelay: Bool = true,
        withPipeliningAssistance: Bool = true,
        readTimeout: TimeAmount = .seconds(30),
        writeTimeout: TimeAmount = .minutes(3)
    ) {
        self.plugins = plugins
        self.commands = commands
        self.maxUploadSize = maxUploadSize
        self.maxStreamingBufferSize = maxStreamingBufferSize
        self.backlog = backlog
        self.tcpNoDelay = tcpNoDelay
        self.withPipeliningAssistance = withPipeliningAssistance
        self.readTimeout = readTimeout
        self.writeTimeout = writeTimeout
    }
}
