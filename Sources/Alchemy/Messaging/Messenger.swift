public struct Messenger<C: Channel>: Service {
    public struct Identifier: ServiceIdentifier {
        private let hashable: AnyHashable
        public init(hashable: AnyHashable) { self.hashable = hashable }
    }
    
    let _send: (C.Message, C.Receiver) async throws -> Void
    
    public init<P: ChannelProvider>(provider: P) where P.C == C {
        self._send = provider.send
    }
    
    public func send(message: C.Message, receiver: C.Receiver) async throws {
        try await _send(message, receiver)
    }
}
