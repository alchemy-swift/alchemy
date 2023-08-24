import HummingbirdCore

struct HTTPPlugin: Plugin {
    func registerServices(in app: Application) {
        app.container.registerSingleton(HBHTTPServer(group: LoopGroup, configuration: hummingbirdConfiguration(for: app)))
        app.container.registerSingleton(Router())
        app.container.registerSingleton(Client())
    }

    func shutdownServices(in app: Application) async throws {
        try app.container.resolve(Client.self)?.shutdown()
        try await app.container.resolve(HBHTTPServer.self)?.stop().get()
    }

    private func hummingbirdConfiguration(for app: Application) -> HBHTTPServer.Configuration {
        let socket = CommandLine.value(for: "--socket") ?? nil
        let host = CommandLine.value(for: "--host") ?? kDefaultHost
        let port = (CommandLine.value(for: "--port").map { Int($0) } ?? nil) ?? kDefaultPort
        let configuration = app.configuration
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
        Container.resolveAssert()
    }
}
