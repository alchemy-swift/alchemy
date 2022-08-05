// MARK: Aliases

public var Email: EmailMessenger { .default }
public func Email(_ id: EmailMessenger.Identifier) -> EmailMessenger { .id(id) }

// MARK: SMSMessenger

public typealias EmailMessenger = Messenger<EmailChannel>

extension EmailMessenger {
    public func send(_ message: EmailMessage, toEmail: String, from fromEmail: String? = nil) async throws {
        var copy = message
        copy.from = fromEmail
        try await send(copy, to: EmailRecipient(email: toEmail))
    }
    
    public func send(_ message: EmailMessage, to receiver: EmailReceiver) async throws {
        try await send(message, to: receiver.emailRecipient)
    }

    public func send(subject: String, content: String, from fromEmail: String? = nil, to receiver: EmailReceiver) async throws {
        try await send(EmailMessage(subject: subject, content: content, from: fromEmail), to: receiver.emailRecipient)
    }

    public func send(subject: String, content: String, from fromEmail: String? = nil, to email: String) async throws {
        try await send(EmailMessage(subject: subject, content: content, from: fromEmail), to: EmailRecipient(email: email))
    }
}

// MARK: Config + Email

extension AnyChannelConfig where Self == EmailMessenger.ChannelConfig {
    public static func email(_ messengers: [EmailMessenger.Identifier: EmailMessenger]) -> AnyChannelConfig {
        EmailMessenger.ChannelConfig(messengers: messengers)
    }
}
