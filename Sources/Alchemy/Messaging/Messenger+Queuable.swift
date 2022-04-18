extension Messenger where C.Message: Codable, C.Receiver: Codable, C.Message: Queueable {
    public init<P: ChannelProvider>(provider: P, saveInDatabase: Bool = false, preferQueueing: Bool = false) where P.C == C {
        JobDecoding.register(MessageJob<C>.self)
        self._send = provider.send
        self.saveInDatabase = saveInDatabase
        self.preferQueueing = preferQueueing
    }
    
    public func sendNow(_ message: C.Message, to receiver: C.Receiver) async throws where C.Message: Codable, C.Message: Queueable {
        try await _send(message, receiver)
        try await _saveInDatabase(message, to: receiver)
    }
    
    public func send(_ message: C.Message, to receiver: C.Receiver) async throws where C.Message: Codable, C.Receiver: Codable, C.Message: Queueable {
        if preferQueueing {
            try await enqueue(message, to: receiver)
        } else {
            try await _send(message, receiver)
        }
        
        try await _saveInDatabase(message, to: receiver)
    }
    
    private func enqueue(_ message: C.Message, to receiver: C.Receiver) async throws where C.Message: Codable, C.Receiver: Codable, C.Message: Queueable {
        try await MessageJob<C>(message: message, receiver: receiver).dispatch()
    }
}

struct MessageJob<C: Channel>: Job where C.Message: Codable & Queueable, C.Receiver: Codable {
    let message: C.Message
    let receiver: C.Receiver
    
    func run() async throws {
        try await Messenger<C>.default.sendNow(message, to: receiver)
    }
}

public protocol Queueable {}
