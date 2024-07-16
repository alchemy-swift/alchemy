import AsyncKit
import Atomics
import Foundation
import PostgresNIO

public struct PostgresConfiguration: ConnectionPoolSource {
    public static let defaultPort = 5432

    public var configuration: PostgresConnection.Configuration

    /// Optional `search_path` to set on new connections.
    public var searchPath: [String]?

    public init(url: String) {
        guard let url = URL(string: url) else {
            preconditionFailure("Unable to initialize Postgres URL from string '\(url)'.")
        }

        self.init(url: url)
    }

    /// Create a ``PostgresConfiguration`` from a properly formatted URL.
    ///
    /// The allowed URL format is:
    ///
    ///     postgres://username:password@hostname:port/database?tls=mode
    ///
    /// `hostname` and `username` are required; all other components are optional. For backwards
    /// compatibility, `ssl` is treated as an alias of `tls`.
    ///
    /// The allowed `mode` values for `tls` are:
    ///   - `require` (fail to connect if the server does not support TLS)
    ///   - `true` (attempt to use TLS but continue anyway if the server doesn't support it)
    ///   - `false` (do not use TLS even if the server supports it).
    /// If `tls` is omitted entirely, the mode defaults to `true`.
    public init(url: URL) {
        guard
            url.scheme?.hasPrefix("postgres") == true,
            let username = url.user,
            let hostname = url.host
        else {
            preconditionFailure("Unable to initialize Postgres URL from url '\(url)'.")
        }

        let tls: PostgresConnection.Configuration.TLS
        let queries = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems ?? []
        let tlsQueries = ["ssl", "tls"]
        let tlsPreference = queries
            .first(where: { tlsQueries.contains($0.name.lowercased()) })?
            .value ?? "true"

        switch tlsPreference {
        case "require":
            tls = .require(TLSConfiguration.makeClientConfiguration().sslContext)
        case "true":
            tls = .prefer(TLSConfiguration.makeClientConfiguration().sslContext)
        case "false":
            tls = .disable
        default:
            preconditionFailure("Unknown TLS preference in Postgres URL '\(tlsPreference)'.")
        }

        self.init(
            hostname: hostname,
            port: url.port ?? PostgresConfiguration.defaultPort,
            username: username,
            password: url.password,
            database: url.lastPathComponent,
            tls: tls
        )
    }

    public init(
        hostname: String,
        port: Int = PostgresConfiguration.defaultPort,
        username: String,
        password: String? = nil,
        database: String? = nil,
        tls: PostgresConnection.Configuration.TLS
    ) {
        self.init(configuration: .init(host: hostname, port: port, username: username, password: password, database: database, tls: tls))
    }

    public init(
        unixDomainSocketPath: String,
        username: String,
        password: String? = nil,
        database: String? = nil
    ) {
        self.init(configuration: .init(unixSocketPath: unixDomainSocketPath, username: username, password: password, database: database))
    }

    public init(
        establishedChannel: Channel,
        username: String,
        password: String? = nil,
        database: String? = nil
    ) {
        self.init(configuration: .init(establishedChannel: establishedChannel, username: username, password: password, database: database))
    }

    public init(
        configuration: PostgresConnection.Configuration,
        searchPath: [String]? = nil
    ) {
        self.configuration = configuration
        self.searchPath = searchPath
    }

    public func makeConnection(logger: Logger, on eventLoop: EventLoop) -> EventLoopFuture<PostgresConnection> {
        struct ID {
            static let generator = ManagedAtomic<Int>(0)
        }

        let connectionFuture = PostgresConnection.connect(
            on: eventLoop,
            configuration: self.configuration,
            id: ID.generator.wrappingIncrementThenLoad(ordering: .relaxed),
            logger: logger
        )

        if let searchPath {
            return connectionFuture.flatMap { conn in
                let string = searchPath.map { #""\#($0)""# }.joined(separator: ", ")
                return conn.simpleQuery("SET search_path = \(string)").map { _ in conn }
            }
        } else {
            return connectionFuture
        }
    }
}
