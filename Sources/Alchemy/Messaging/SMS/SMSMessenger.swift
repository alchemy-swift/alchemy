// MARK: Aliases

public var SMS: SMSMessenger { .default }
public func SMS(_ id: SMSMessenger.Identifier) -> SMSMessenger { .id(id) }

// MARK: SMSMessenger

public typealias SMSMessenger = Messenger<SMSChannel>

extension SMSMessenger {
    private struct _OneOffReceiver: SMSReceiver {
        let phone: String
    }
    
    public func send(_ message: SMSMessage, toPhone: String, fromPhone: String? = nil) async throws {
        var copy = message
        copy.from = fromPhone
        try await send(copy, to: _OneOffReceiver(phone: toPhone))
    }
}

// MARK: Config + SMS

extension AnyChannelConfig where Self == SMSMessenger.ChannelConfig {
    static func sms(_ messengers: [SMSMessenger.Identifier: SMSMessenger]) -> AnyChannelConfig {
        SMSMessenger.ChannelConfig(messengers: messengers)
    }
}
