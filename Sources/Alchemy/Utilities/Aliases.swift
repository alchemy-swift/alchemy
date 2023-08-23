import Crypto
import Fusion

/// The default configured Client
public var Http: Client.Builder { Container.resolveAssert(Client.self).builder() }
public func Http(_ id: Client.Identifier) -> Client.Builder { Container.resolveAssert(Client.self, id: id).builder() }

/// The default configured Database
public var DB: Database { Container.resolveAssert() }
public func DB(_ id: Database.Identifier?) -> Database { Container.resolveAssert(id: id) }

/// The application Lifecycle
public var Lifecycle: ServiceLifecycle { Container.resolveAssert() }

/// The application Environment
public var Env: Environment { Container.resolveAssert() }

/// The application Logger
public var Log: Logger {
    get {
        guard let logger: Logger = Container.resolve() else {
            let logger = Logger.default
            Container.main.registerSingleton(logger)
            return logger
        }

        return logger
    }
    set { Container.main.registerSingleton(newValue) }
}
public func Log(_ id: Logger.Identifier) -> Logger { Container.resolveAssert(id: id) }
public func Log(_ ids: Logger.Identifier...) -> Logger {
    Logger(loggers: ids.map { Container.resolveAssert(id: $0) })
}

/// The appliation Router
public var Routes: Router { Container.resolveAssert() }

/// The appliation Router
public var Schedule: Scheduler { Container.resolveAssert() }

/// The default configured Filesystem
public var Storage: Filesystem { Container.resolveAssert() }
public func Storage(_ id: Filesystem.Identifier) -> Filesystem { Container.resolveAssert(id: id) }

/// Your app's default Cache.
public var Stash: Cache { Container.resolveAssert() }
public func Stash(_ id: Cache.Identifier) -> Cache { Container.resolveAssert(id: id) }

/// Your app's default Queue
public var Q: Queue { Container.resolveAssert() }
public func Q(_ id: Queue.Identifier) -> Queue { Container.resolveAssert(id: id) }

/// Your app's default RedisClient
public var Redis: RedisClient { Container.resolveAssert() }
public func Redis(_ id: RedisClient.Identifier) -> RedisClient { Container.resolveAssert(id: id) }

/// Accessor for firing events; applications should listen to events via
/// `Application.schedule(events: EventBus)`.
public var Events: EventBus { Container.resolveAssert() }

/// Accessors for Hashing
public var Hash: Hasher<BCryptHasher> { Hasher(algorithm: .bcrypt) }
public func Hash<Algorithm: HashAlgorithm>(_ algorithm: Algorithm) -> Hasher<Algorithm> { Hasher(algorithm: algorithm) }

/// Accessor for encryption
public var Crypt: Encrypter { Encrypter(key: .app) }
public func Crypt(key: SymmetricKey) -> Encrypter { Encrypter(key: key) }

/// The event loop your code is currently running on, or the next available one
/// if your code isn't running on an `EventLoop`.
public var Loop: EventLoop { Container.resolveAssert() }

/// The main `EventLoopGroup` of your Application.
public var LoopGroup: EventLoopGroup { Container.resolveAssert() }

/// A thread pool to run expensive work on.
public var Thread: NIOThreadPool { Container.resolveAssert() }
