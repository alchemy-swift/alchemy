import Papyrus

extension Messenger where C.Message: Codable {
    public init<P: ChannelProvider>(provider: P, saveInDatabase: Bool = false) where P.C == C {
        self._send = provider.send
        self.saveInDatabase = saveInDatabase
        self.preferQueueing = false
    }
    
    public func send(_ message: C.Message, to receiver: C.Receiver) async throws {
        try await _send(message, receiver)
        try await _saveInDatabase(message, to: receiver)
    }
    
    func _saveInDatabase(_ message: C.Message, to receiver: C.Receiver) async throws {
        if saveInDatabase {
            try await DatabaseMessage(channel: C.self, message: message).save()
        }
    }
}

struct DatabaseMessage: Model, Timestamps {
    static let tableName: String = "messages"
    
    var id: Int?
    let channel: String
    let message: JSONString
    let receiver: JSONString
}

extension DatabaseMessage {
    init<C: Channel, M: Codable>(channel: C.Type, message: M) throws {
        self.channel = C.identifier
        self.message = try message.jsonString()
        self.receiver = try message.jsonString()
    }
}

public struct AddMessagesMigration: Migration {
    public init() {}
    
    public func up(schema: Schema) {
        schema.create(table: DatabaseMessage.tableName) {
            $0.increments("id").primary()
            $0.string("channel").notNull()
            $0.string("message", length: .unlimited).notNull()
            $0.string("receiver", length: .unlimited).notNull()
            $0.timestamps()
        }
    }
    
    public func down(schema: Schema) {
        schema.drop(table: DatabaseMessage.tableName)
    }
}
