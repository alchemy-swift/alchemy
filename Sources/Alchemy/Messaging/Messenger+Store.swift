extension Messenger where C.Message: Codable, C.Receiver: Codable {

    // MARK: Storing

    public func store(_ store: Bool = true) -> Self {
        Self(_send: _send, _shutdown: _shutdown, saveInDatabase: store, preferQueueing: queue)
    }

    public func dontStore() -> Self {
        store(false)
    }
}

struct DatabaseMessage<Message: Codable, Receiver: Codable>: Model {
    static var table: String { "messages" }

    var id: PK<Int> = .new
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
