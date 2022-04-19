extension Messenger where C.Message: Codable, C.Receiver: Codable {
    public func send(_ message: C.Message, to receiver: C.Receiver) async throws {
        if queue {
            try await _enqueue(message, to: receiver)
            try await _saveInDatabase(message, to: receiver)
        } else {
            try await _send(message, receiver)
            try await _saveInDatabase(message, to: receiver)
        }
    }
    
    private func _enqueue(_ message: C.Message, to receiver: C.Receiver) async throws {
        try await MessageJob<C>(message: message, receiver: receiver).dispatch()
    }
    
    private func _saveInDatabase(_ message: C.Message, to receiver: C.Receiver) async throws {
        if store {
            try await DatabaseMessage(channel: C.self, message: message, receiver: receiver).save()
        }
    }
}

extension Messenger where C.Message: Codable, C.Receiver: Codable {
    
    // MARK: Queueing
    
    public func queue(_ queue: Bool = true) -> Self {
        JobDecoding.register(MessageJob<C>.self)
        return Self(_send: _send, saveInDatabase: store, preferQueueing: queue)
    }
    
    public func immediately() -> Self {
        queue(false)
    }

    // MARK: Storing
    
    public func store(_ store: Bool = true) -> Self {
        Self(_send: _send, saveInDatabase: store, preferQueueing: queue)
    }
    
    public func dontStore() -> Self {
        store(false)
    }
}

private struct MessageJob<C: Channel>: Job where C.Message: Codable, C.Receiver: Codable {
    let message: C.Message
    let receiver: C.Receiver
    
    func run() async throws {
        try await Messenger<C>.default._send(message, receiver)
    }
}

struct DatabaseMessage<Message: Codable, Receiver: Codable>: Model {
    static var tableName: String { "messages" }
    
    var id: Int?
    let channel: String
    let message: Message
    let receiver: Receiver
    
    init<C: Channel>(channel: C.Type, message: Message, receiver: Receiver) throws {
        self.channel = C.identifier
        self.message = message
        self.receiver = receiver
    }
}

public struct AddMessagesMigration: Migration {
    public init() {}
    
    public func up(schema: Schema) {
        schema.create(table: "messages") {
            $0.increments("id").primary()
            $0.string("channel").notNull()
            $0.json("message").notNull()
            $0.json("receiver").notNull()
            $0.timestamps()
        }
    }
    
    public func down(schema: Schema) {
        schema.drop(table: "messages")
    }
}
