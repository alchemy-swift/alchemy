// MARK: EmailChannel

public struct EmailChannel: Channel {
    public typealias Message = EmailMessage
    public typealias Receiver = EmailRecipient
}

// MARK: EmailMessage

public struct EmailMessage: Codable {
    public let subject: String
    public let content: String
    public var from: String?

    public init(subject: String, content: String, from: String? = nil) {
        self.subject = subject
        self.content = content
        self.from = from
    }

    public func send<R: EmailReceiver>(to receiver: R, via sender: EmailMessenger = .default) async throws {
        try await sender.send(self, to: receiver.emailRecipient)
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

// MARK: EmailReceiver

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
