/// The information needed to connect to a database.
public struct DatabaseConfig {
    /// The socket where this database server is available.
    public let socket: Socket
    /// The name of the database on the database server to connect to.
    public let database: String
    /// The username to connect to the database with.
    public let username: String
    /// The password to connect to the database with.
    public let password: String
    /// Should the connection use SSL.
    public let enableSSL: Bool
    
    /// Initialize a database configuration with the relevant info.
    ///
    /// - Parameters:
    ///   - socket: The location of the database.
    ///   - database: The name of the database to connect to.
    ///   - username: The username to connect with.
    ///   - password: The password to connect with.
    ///   - enableSSL: Should the connection use SSL.
    public init(socket: Socket, database: String, username: String, password: String, enableSSL: Bool = false) {
        self.socket = socket
        self.database = database
        self.username = username
        self.password = password
        self.enableSSL = enableSSL
    }
}
