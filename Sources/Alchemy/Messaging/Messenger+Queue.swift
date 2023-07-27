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
        return Self(_send: _send, _shutdown: _shutdown, saveInDatabase: store, preferQueueing: queue)
    }
    
    public func immediately() -> Self {
        queue(false)
    }
}

private struct MessageJob<C: MessageChannel>: Job where C.Message: Codable, C.Receiver: Codable {
    let message: C.Message
    let receiver: C.Receiver
    
    func run() async throws {
        try await Messenger<C>.default._send(message, receiver)
    }
}
