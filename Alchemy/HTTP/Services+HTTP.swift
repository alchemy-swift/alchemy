import Crypto

// MARK: Aliases

/// The application Router
public var Routes: Router {
    Container.$router
}

/// The default configured Client
public var Http: Client.Builder {
    Container.$client.builder()
}

public func Http(_ key: KeyPath<Container, Client>) -> Client.Builder {
    Container.main[keyPath: key].builder()
}

/// Accessors for Hashing
public var Hash: Hasher {
    get { Container.$hasher }
    set { Container.$hasher = newValue }
}

public func Hash(_ algorithm: HashAlgorithm) -> Hasher {
    Hasher(algorithm: algorithm)
}

/// Accessor for encryption
public var Crypt: Encrypter {
    Encrypter(key: .app)
}

public func Crypt(key: SymmetricKey) -> Encrypter {
    Encrypter(key: key)
}

// MARK: Internal

/// For easy `Client` access - the public `Http` exposes a `Client.Builder`.
var _Http: Client {
    Container.$client
}

var Handle: HTTPHandler {
    Container.$handler
}

extension Container {
    @Singleton var hasher = Hasher(algorithm: .bcrypt)
    @Singleton var handler = HTTPHandler(router: $router)
    @Singleton var router = HTTPRouter()
    @Singleton var client = Client()
}
