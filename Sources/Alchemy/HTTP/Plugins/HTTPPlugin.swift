import HummingbirdCore

struct HTTPPlugin: Plugin {
    func registerServices(in app: Application) {
        let configuration = app.configuration
        let hbConfiguration = hummingbirdConfiguration(for: configuration)
        app.container.register { HBHTTPServer(group: $0.require(), configuration: hbConfiguration) }.singleton()
        app.container.register(HTTPRouter()).singleton()
        app.container.register { HTTPHandler(maxUploadSize: configuration.maxUploadSize, router: $0.require() as HTTPRouter) }.singleton()
        app.container.register { $0.require() as HTTPRouter as Router }
        app.container.register { $0.require() as HTTPHandler as RequestHandler }
        app.container.register(Client()).singleton()
    }

    func shutdownServices(in app: Application) async throws {
        try app.container.resolve(Client.self)?.shutdown()
        try await app.container.resolve(HBHTTPServer.self)?.stop().get()
    }

    private func hummingbirdConfiguration(for configuration: Application.Configuration) -> HBHTTPServer.Configuration {
        let socket = CommandLine.value(for: "--socket") ?? nil
        let host = CommandLine.value(for: "--host") ?? kDefaultHost
        let port = (CommandLine.value(for: "--port").map { Int($0) } ?? nil) ?? kDefaultPort
        return HBHTTPServer.Configuration(
            address: {
                if let socket {
                    return .unixDomainSocket(path: socket)
                } else {
                    return .hostname(host, port: port)
                }
            }(),
            maxUploadSize: configuration.maxUploadSize,
            maxStreamingBufferSize: configuration.maxStreamingBufferSize,
            backlog: configuration.backlog,
            tcpNoDelay: configuration.tcpNoDelay,
            withPipeliningAssistance: configuration.withPipeliningAssistance,
            idleTimeoutConfiguration: HBHTTPServer.IdleStateHandlerConfiguration(
                readTimeout: configuration.readTimeout,
                writeTimeout: configuration.writeTimeout
            )
        )
    }
}

extension Application {
    public var server: HBHTTPServer {
        Container.require()
    }
}
