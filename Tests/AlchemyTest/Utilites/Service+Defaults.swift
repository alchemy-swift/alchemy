import AlchemyTest

var Http: Client {
    @Inject var client: Client
    return client
}

var DB: Database {
    @Inject var database: Database
    return database
}

var Jobs: Queue {
    @Inject var queue: Queue
    return queue
}

var Red: Redis {
    @Inject var redis: Redis
    return redis
}
