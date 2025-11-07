import Crypto

// MARK: Aliases

/// The application Router
public var Routes: Router {
    Container.router
}

public var Handle: HTTPHandler {
    Container.handler
}

/// The default configured Client
public var Http: Client.Builder {
    Container.client.builder()
}

public func Http(_ key: KeyPath<Container, Client>) -> Client.Builder {
    Container.main[keyPath: key].builder()
}

/// Accessors for Hashing
public var Hash: Hasher {
    get { Container.hasher }
    set { Container.hasher = newValue }
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
    Container.client
}

extension Container {
    @Service(.singleton) public var hasher = Hasher(algorithm: .bcrypt)
    @Service(.singleton) public var handler = HTTPHandler(router: router)
    @Service(.singleton) public var client = Client()
    @Service(.singleton) var router = HTTPRouter()
}
