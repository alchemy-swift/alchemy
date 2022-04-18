import Papyrus

extension Messenger where C.Message: Codable, C.Receiver: Codable {
    public func send(_ message: C.Message, to receiver: C.Receiver) async throws {
        try await _send(message, receiver)
        try await _saveInDatabase(message, to: receiver)
    }
    
    func _saveInDatabase(_ message: C.Message, to receiver: C.Receiver) async throws {
        if saveInDatabase {
            try await DatabaseMessage(channel: C.self, message: message, receiver: receiver).save()
        }
    }
}

struct DatabaseMessage<Message: Codable, Receiver: Codable>: Model, Timestamps {
    static var tableName: String { "messages" }
    
    var id: Int?
    let channel: String
    let message: Message
    let receiver: Receiver
}

extension DatabaseMessage {
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
