import Crypto
import Fusion

/// The default configured Client
public var Http: Client.Builder { Container.resolveAssert(Client.self).builder() }
public func Http(_ id: Client.Identifier) -> Client.Builder { Container.resolveAssert(Client.self, identifier: id).builder() }

/// The default configured Database
public var DB: Database { Container.resolveAssert(identifier: nil) }
public func DB(_ id: Database.Identifier?) -> Database { Container.resolveAssert(identifier: id) }

/// The application Lifecycle
public var Lifecycle: ServiceLifecycle { Container.resolveAssert() }

/// The application Environment
public var Env: Environment { Container.resolveAssert() }

/// The appliation Router
public var Routes: Router { Container.resolveAssert() }

/// The default configured Filesystem
public var Storage: Filesystem { Container.resolveAssert(identifier: nil) }
public func Storage(_ id: Filesystem.Identifier) -> Filesystem { Container.resolveAssert(identifier: id) }

/// Your app's default Cache.
public var Stash: Cache { Container.resolveAssert(identifier: nil) }
public func Stash(_ id: Cache.Identifier) -> Cache { Container.resolveAssert(identifier: id) }

/// Your app's default Queue
public var Q: Queue { Container.resolveAssert(identifier: nil) }
public func Q(_ id: Queue.Identifier) -> Queue { Container.resolveAssert(identifier: id) }

/// Your app's default RedisClient
public var Redis: RedisClient { Container.resolveAssert(identifier: nil) }
public func Redis(_ id: RedisClient.Identifier) -> RedisClient { Container.resolveAssert(identifier: id) }

/// Accessor for firing events; applications should listen to events via
/// `Application.schedule(events: EventBus)`.
public var Events: EventBus { Container.resolveAssert(identifier: nil) }

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
