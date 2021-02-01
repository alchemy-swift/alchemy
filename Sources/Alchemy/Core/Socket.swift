import NIO

/// A type representing a communication link between two programs
/// running on a network. A server can bind to a socket when serving
/// (i.e. this is where the server can be reached). Other network
/// interfaces can also be reached via a socket, such as a database.
/// Either an ip host & port or a unix socket path.
public enum Socket {
    /// An ip address `host` at port `port`.
    case ip(host: String, port: Int)
    /// A unix domain socket (IPC socket) at path `path`.
    case unix(path: String)
}

extension Socket {
    /// The `NIO.SocketAddress` representing this `Socket`.
    var nio: SocketAddress {
        do {
            switch self {
            case let .ip(host, port):
                return try .makeAddressResolvingHost(host, port: port)
            case let .unix(path):
                return try .init(unixDomainSocketPath: path)
            }
        } catch {
            fatalError("Error generating socket address from `Socket` \(self)!")
        }
    }
}
