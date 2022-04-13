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

struct DatabaseMessage: Model {
    static let tableName: String = "notifications"
    
    var id: Int?
    let channel: String
    let json: JSONString
}

extension DatabaseMessage {
    init<C: Channel, M: Codable>(channel: C.Type, message: M) throws {
        self.channel = C.identifier
        self.json = try message.jsonString()
    }
}
