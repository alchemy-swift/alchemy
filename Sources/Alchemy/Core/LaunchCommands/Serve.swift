import ArgumentParser

/// Command to serve on launched. This is a subcommand of `Launch`. The app will
/// route with the singleton `HTTPRouter`.
struct Serve<A: Application>: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "serve")
    }
    
    /// The host to serve at. Defaults to `::1` aka `localhost`.
    @Option
    var host = "::1"

    /// The port to serve at. Defaults to `8888`.
    @Option
    var port = 8888
    
    /// The unix socket to serve at. If this is provided, the host and port will
    /// be ignored.
    @Option
    var unixSocket: String?
    
    func run() throws {
        let socket: Socket = self.unixSocket
            .map { .unix(path: $0) } ?? .ip(host: self.host, port: self.port)
        try A().launch(.serve(socket: socket))
    }
}
