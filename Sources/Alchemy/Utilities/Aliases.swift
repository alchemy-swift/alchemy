// The default configured Client
public var Http: Client { .resolve(.default) }

// The default configured Database
public var DB: Database { .resolve(.default) }

// The default configured Filesystem
public var Storage: Filesystem { .resolve(.default) }

// Your apps default cache.
public var Cache: Store { .resolve(.default) }

// TODO: Redis after async
