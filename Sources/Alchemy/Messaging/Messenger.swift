public struct Messenger<C: Channel>: Service {
    public struct Identifier: ServiceIdentifier {
        private let hashable: AnyHashable
        public init(hashable: AnyHashable) { self.hashable = hashable }
    }

    let _send: (C.Message, C.Receiver) async throws -> Void
    fileprivate(set) var saveInDatabase: Bool
    fileprivate(set) var preferQueueing: Bool
    
    public init<P: ChannelProvider>(provider: P) where P.C == C {
        self._send = provider.send
        self.saveInDatabase = false
        self.preferQueueing = false
    }
    
    fileprivate init(_send: @escaping (C.Message, C.Receiver) async throws -> Void, saveInDatabase: Bool, preferQueueing: Bool) {
        self._send = _send
        self.saveInDatabase = saveInDatabase
        self.preferQueueing = preferQueueing
    }
    
    public func send(_ message: C.Message, to receiver: C.Receiver) async throws {
        try await _send(message, receiver)
    }
}

extension Messenger where C.Message: Codable, C.Receiver: Codable {
    public func store(_ store: Bool = true) -> Self {
        Self(_send: _send, saveInDatabase: store, preferQueueing: preferQueueing)
    }
    
    public func dontStore() -> Self {
        store(false)
    }
}

extension Messenger where C.Message: Codable & Queueable, C.Receiver: Codable {
    public func queue(_ queue: Bool = true) -> Self {
        JobDecoding.register(MessageJob<C>.self)
        return Self(_send: _send, saveInDatabase: saveInDatabase, preferQueueing: queue)
    }
    
    public func immediately() -> Self {
        queue(false)
    }
}
