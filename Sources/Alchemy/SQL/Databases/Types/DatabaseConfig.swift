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
    
    /// Initialize a database configuration with the relevant info.
    ///
    /// - Parameters:
    ///   - socket: the location of the database.
    ///   - database: the name of the database to connect to.
    ///   - username: the username to connect with.
    ///   - password: the password to connect with.
    public init(
        socket: Socket,
        database: String,
        username: String,
        password: String
    ) {
        self.socket = socket
        self.database = database
        self.username = username
        self.password = password
    }
}
