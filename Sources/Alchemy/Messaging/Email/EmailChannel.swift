// MARK: SMSChannel

public struct EmailChannel: Channel {
    public typealias Message = EmailMessage
    public typealias Receiver = EmailRecipient
}

// MARK: SMSMessage

public struct EmailMessage: Codable {
    public let body: String
    public var from: String?
    
    public func send<R: EmailReceiver>(to receiver: R, via sender: EmailMessenger = .default) async throws {
        try await sender.send(self, to: receiver.emailRecipient)
    }
}

extension EmailMessage: ExpressibleByStringInterpolation {
    public init(stringLiteral value: String) {
        self.init(body: value)
    }
}

public struct EmailRecipient: Codable {
    public let email: String
    
    public init(email: String) {
        self.email = email
    }
}

extension EmailRecipient: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.email = value
    }
}

// MARK: SMSReceiver

public protocol EmailReceiver {
    var email: String { get }
}

extension EmailReceiver {
    var emailRecipient: EmailRecipient {
        EmailRecipient(email: email)
    }
    
    public func send(email: EmailMessage, via sender: EmailMessenger = .default) async throws {
        try await sender.send(email, to: emailRecipient)
    }
}
