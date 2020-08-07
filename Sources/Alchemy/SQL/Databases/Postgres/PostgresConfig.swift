public struct PostgresConfig {
    public enum Socket {
        case ipAddress(host: String, port: Int)
        case unixSocket(path: String)
    }
    
    public let socket: Socket
    public let database: String
    public let username: String
    public let password: String
    
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
