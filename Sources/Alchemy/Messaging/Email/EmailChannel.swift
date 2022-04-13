// MARK: SMSChannel

public struct EmailChannel: Channel {
    public typealias Message = EmailMessage
    public typealias Receiver = EmailReceiver
}

// MARK: SMSMessage

public struct EmailMessage: Codable, Queueable {
    public let body: String
    public var from: String?
    
    public func send<R: EmailReceiver>(to receiver: R, via sender: EmailMessenger = .default) async throws {
        try await sender.send(self, to: receiver)
    }
}

extension EmailMessage: ExpressibleByStringInterpolation {
    public init(stringLiteral value: String) {
        self.init(body: value)
    }
}

// MARK: SMSReceiver

public protocol EmailReceiver {
    var email: String { get }
}

extension EmailReceiver {
    public func send(email: EmailMessage, via sender: EmailMessenger = .default) async throws {
        try await sender.send(email, to: self)
    }
}
