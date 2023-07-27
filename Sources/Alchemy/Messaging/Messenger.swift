public struct Messenger<C: MessageChannel>: Service {
    public struct Identifier: ServiceIdentifier {
        private let hashable: AnyHashable
        public init(hashable: AnyHashable) { self.hashable = hashable }
    }

    let _send: (C.Message, C.Receiver) async throws -> Void
    let _shutdown: () throws -> Void
    fileprivate(set) var store: Bool
    fileprivate(set) var queue: Bool
    
    public init<P: MessageChannelProvider>(provider: P) where P.C == C {
        self._send = provider.send
        self._shutdown = provider.shutdown
        self.store = false
        self.queue = false
    }
    
    init(_send: @escaping (C.Message, C.Receiver) async throws -> Void, _shutdown: @escaping () throws -> Void, saveInDatabase: Bool, preferQueueing: Bool) {
        self._send = _send
        self._shutdown = _shutdown
        self.store = saveInDatabase
        self.queue = preferQueueing
    }
    
    public func send(_ message: C.Message, to receiver: C.Receiver) async throws {
        try await _send(message, receiver)
    }

    public func shutdown() throws {
        try _shutdown()
    }
}
