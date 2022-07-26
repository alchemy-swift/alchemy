// MARK: Aliases

public var Email: EmailMessenger { .default }
public func Email(_ id: EmailMessenger.Identifier) -> EmailMessenger { .id(id) }

// MARK: SMSMessenger

public typealias EmailMessenger = Messenger<EmailChannel>

extension EmailMessenger {
    public func send(_ message: EmailMessage, toEmail: String, fromEmail: String? = nil) async throws {
        var copy = message
        copy.from = fromEmail
        try await send(copy, to: EmailRecipient(email: toEmail))
    }
    
    public func send(_ message: EmailMessage, to receiver: EmailReceiver) async throws {
        try await send(message, to: receiver.emailRecipient)
    }
}

// MARK: Config + Email

extension AnyChannelConfig where Self == EmailMessenger.ChannelConfig {
    public static func email(_ messengers: [EmailMessenger.Identifier: EmailMessenger]) -> AnyChannelConfig {
        EmailMessenger.ChannelConfig(messengers: messengers)
    }
}
