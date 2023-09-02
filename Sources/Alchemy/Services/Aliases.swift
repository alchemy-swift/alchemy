import Crypto

// MARK: Public Aliases

/// The default configured Client
public var Http: Client.Builder { Container.require(Client.self).builder() }
public func Http(_ id: Client.Identifier) -> Client.Builder { Container.require(Client.self, id: id).builder() }

/// The default configured Database
public var DB: Database { Container.require() }
public func DB(_ id: Database.Identifier?) -> Database { Container.require(id: id) }

/// The application Lifecycle
public var Lifecycle: ServiceLifecycle { Container.require() }

/// The application Environment
public var Env: Environment { Container.require() }

/// The application Logger
public var Log: Logger {
    get {
        guard let logger = Container.resolve(Logger.self) else {
            /// If a logger hasn't been registered yet, register one with
            /// sensible defaults.
            let logger = Logger.default
            Container.register(logger).singleton()
            return logger
        }

        return logger
    }
    set { Container.register(newValue).singleton() }
}
public func Log(_ id: Logger.Identifier) -> Logger { Container.require(id: id) }
public func Log(_ ids: Logger.Identifier...) -> Logger {
    Logger(loggers: ids.map { Container.require(id: $0) })
}

/// The application Router
public var Routes: Router { Container.require() }

/// The appliation Router
public var Schedule: Scheduler { Container.require() }

/// The default configured Filesystem
public var Storage: Filesystem { Container.require() }
public func Storage(_ id: Filesystem.Identifier) -> Filesystem { Container.require(id: id) }

/// Your app's default Cache.
public var Stash: Cache { Container.require() }
public func Stash(_ id: Cache.Identifier) -> Cache { Container.require(id: id) }

/// Your app's default Queue
public var Q: Queue { Container.require() }
public func Q(_ id: Queue.Identifier) -> Queue { Container.require(id: id) }

/// Your app's default RedisClient
public var Redis: RedisClient { Container.require() }
public func Redis(_ id: RedisClient.Identifier) -> RedisClient { Container.require(id: id) }

/// Accessor for firing events; applications should listen to events via
/// `Application.schedule(events: EventBus)`.
public var Events: EventBus { Container.require() }

/// Accessors for Hashing
public var Hash: Hasher<BCryptHasher> { Hasher(algorithm: .bcrypt) }
public func Hash<Algorithm: HashAlgorithm>(_ algorithm: Algorithm) -> Hasher<Algorithm> { Hasher(algorithm: algorithm) }

/// Accessor for encryption
public var Crypt: Encrypter { Encrypter(key: .app) }
public func Crypt(key: SymmetricKey) -> Encrypter { Encrypter(key: key) }

/// The `EventLoop` your code is currently running on, or the next one from your
/// app's `EventLoopGroup` if your code isn't running on an `EventLoop`.
public var Loop: EventLoop { Container.require() }

/// The main `EventLoopGroup` of your Application.
public var LoopGroup: EventLoopGroup { Container.require() }

/// A thread pool to run expensive work on.
public var Thread: NIOThreadPool { Container.require() }

// MARK: Internal

var Jobs: JobRegistry {
    Container.require()
}
