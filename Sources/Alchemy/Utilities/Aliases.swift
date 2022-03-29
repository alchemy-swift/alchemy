/// The default configured Client
public var Http: Client.Builder { Client.id(.default).builder() }
public func Http(_ id: Client.Identifier) -> Client.Builder { Client.id(id).builder() }

/// The default configured Database
public var DB: Database { .id(.default) }
public func DB(_ id: Database.Identifier) -> Database { .id(id) }

/// The default configured Filesystem
public var Storage: Filesystem { .id(.default) }
public func Storage(_ id: Filesystem.Identifier) -> Filesystem { .id(id) }

/// Your app's default Cache.
public var Stash: Cache { .id(.default) }
public func Stash(_ id: Cache.Identifier) -> Cache { .id(id) }

/// Your app's default Queue
public var Q: Queue { .id(.default) }
public func Q(_ id: Queue.Identifier) -> Queue { .id(id) }

/// Your app's default RedisClient
public var Redis: RedisClient { .id(.default) }
public func Redis(_ id: RedisClient.Identifier) -> RedisClient { .id(id) }

/// Internal accessor for firing events; applications should listen to events
/// via Application.schedule(events: EventBus)
var Events: EventBus { .id(.default) }
