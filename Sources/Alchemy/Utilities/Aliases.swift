// The default configured Client
public var Http: Client.Builder { Client.resolve(.default).builder() }

// The default configured Database
public var DB: Database { .resolve(.default) }

// The default configured Filesystem
public var Storage: Filesystem { .resolve(.default) }

// Your app's default Cache.
public var Stash: Cache { .resolve(.default) }

// TODO: Redis after async
