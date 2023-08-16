extension Messenger where C.Message: Codable, C.Receiver: Codable {

    // MARK: Storing

    public func store(_ store: Bool = true) -> Self {
        Self(_send: _send, _shutdown: _shutdown, saveInDatabase: store, preferQueueing: queue)
    }

    public func dontStore() -> Self {
        store(false)
    }
}

struct DatabaseMessage<Message: Codable, Receiver: Codable>: Model, Codable {
    static var table: String { "messages" }

    static var storedProperties: [PartialKeyPath<Self>: String] {
        [
            \Self.id: "id",
            \Self.channel: "channel",
            \Self.message: "message",
            \Self.receiver: "receiver",
        ]
    }

    var id: PK<Int> = .new
    let channel: String
    let message: Message
    let receiver: Receiver

    init<C: MessageChannel>(channel: C.Type, message: Message, receiver: Receiver) throws {
        self.channel = C.identifier
        self.message = message
        self.receiver = receiver
    }
}

public struct AddMessagesMigration: Migration {
    public init() {}

    public func up(db: Database) async throws {
        try await db.createTable("messages") {
            $0.increments("id").primary()
            $0.string("channel").notNull()
            $0.json("message").notNull()
            $0.json("receiver").notNull()
            $0.timestamps()
        }
    }

    public func down(db: Database) async throws {
        try await db.dropTable("messages")
    }
}
