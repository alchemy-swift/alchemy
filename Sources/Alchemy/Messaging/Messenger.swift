public struct Messenger<C: Channel>: Service {
    public struct Identifier: ServiceIdentifier {
        private let hashable: AnyHashable
        public init(hashable: AnyHashable) { self.hashable = hashable }
    }

    let _send: (C.Message, C.Receiver) async throws -> Void
    fileprivate(set) var store: Bool
    fileprivate(set) var queue: Bool
    
    public init<P: ChannelProvider>(provider: P) where P.C == C {
        self._send = provider.send
        self.store = false
        self.queue = false
    }
    
    init(_send: @escaping (C.Message, C.Receiver) async throws -> Void, saveInDatabase: Bool, preferQueueing: Bool) {
        self._send = _send
        self.store = saveInDatabase
        self.queue = preferQueueing
    }
    
    public func send(_ message: C.Message, to receiver: C.Receiver) async throws {
        try await _send(message, receiver)
    }
}
