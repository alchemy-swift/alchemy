import NIO

/// A type representing a communication link between two programs
/// running on a network. A server can bind to a socket when serving
/// (i.e. this is where the server can be reached). Other network
/// interfaces can also be reached via a socket, such as a database.
/// Either an ip host & port or a unix socket path.
public enum Socket: Equatable {
    /// An ip address `host` at port `port`.
    case ip(host: String, port: Int)
    /// A unix domain socket (IPC socket) at path `path`.
    case unix(path: String)
}
