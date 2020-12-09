import ArgumentParser

struct Serve<A: Application>: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "serve")
    }
    
    @Option
    var host = "::1"

    @Option
    var port = 8888
    
    @Option
    var unixSocket: String?
    
    func run() throws {
        let bindTarget = self.unixSocket.map { BindTo.unixDomainSocket(path: $0) } ??
            .ip(host: self.host, port: self.port)
        try A().launch(.serve(target: bindTarget))
    }
}
