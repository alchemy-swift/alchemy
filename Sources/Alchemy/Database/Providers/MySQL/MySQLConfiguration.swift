import AsyncKit
import NIOSSL
import NIOCore
import MySQLNIO
import Logging

public struct MySQLConfiguration: ConnectionPoolSource {
    public static let defaultPort = 3306

    public var address: () throws -> SocketAddress
    public var username: String
    public var password: String?
    public var database: String?
    public var tls: TLSConfiguration?

    internal var _hostname: String?

    public init(url: String) {
        guard let url = URL(string: url) else {
            preconditionFailure("Unable to initialize MySQL URL from string '\(url)'.")
        }

        self.init(url: url)
    }

    public init(url: URL) {
        guard
            url.scheme?.hasPrefix("mysql") == true,
            let username = url.user,
            let hostname = url.host
        else {
            preconditionFailure("Unable to initialize MySQL URL from url '\(url)'.")
        }

        self.init(
            hostname: hostname,
            port: url.port ?? MySQLConfiguration.defaultPort,
            username: username,
            password: url.password,
            database: url.lastPathComponent,
            tls: url.query == "ssl=false" ? nil : .makeClientConfiguration()
        )
    }

    public init(
        unixDomainSocketPath: String,
        username: String,
        password: String,
        database: String? = nil
    ) {
        self.address = {
            try SocketAddress.init(unixDomainSocketPath: unixDomainSocketPath)
        }

        self.username = username
        self.password = password
        self.database = database
        self.tls = nil
        self._hostname = nil
    }

    public init(
        hostname: String,
        port: Int = MySQLConfiguration.defaultPort,
        username: String,
        password: String? = nil,
        database: String? = nil,
        tls: TLSConfiguration? = .makeClientConfiguration()
    ) {
        self.address = {
            try SocketAddress.makeAddressResolvingHost(hostname, port: port)
        }

        self.username = username
        self.database = database
        self.password = password
        if let tls {
            self.tls = tls

            // Temporary fix - this logic should be removed once MySQLNIO is updated
            var n4 = in_addr(), n6 = in6_addr()
            if inet_pton(AF_INET, hostname, &n4) != 1 && inet_pton(AF_INET6, hostname, &n6) != 1 {
                self._hostname = hostname
            }
        }
    }

    // MARK: ConnectionPoolSource

    public func makeConnection(logger: Logger, on eventLoop: EventLoop) -> EventLoopFuture<MySQLConnection> {
        do {
            return MySQLConnection.connect(
                to: try address(),
                username: username,
                database: database ?? username,
                password: password,
                tlsConfiguration: tls,
                serverHostname: _hostname,
                logger: logger,
                on: eventLoop
            )
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }
}
