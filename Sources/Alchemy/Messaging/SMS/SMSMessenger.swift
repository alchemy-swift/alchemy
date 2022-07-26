// MARK: Aliases

public var SMS: SMSMessenger { .default }
public func SMS(_ id: SMSMessenger.Identifier) -> SMSMessenger { .id(id) }

// MARK: SMSMessenger

public typealias SMSMessenger = Messenger<SMSChannel>

extension SMSMessenger {
    public func send(_ message: SMSMessage, toPhone: String, fromPhone: String? = nil) async throws {
        var copy = message
        copy.from = fromPhone
        try await send(copy, to: SMSDevice(number: toPhone))
    }
    
    public func send(_ message: SMSMessage, to receiver: SMSReceiver, fromPhone: String? = nil) async throws {
        try await send(message, toPhone: receiver.phone, fromPhone: fromPhone)
    }
}

// MARK: Config + SMS

extension AnyChannelConfig where Self == SMSMessenger.ChannelConfig {
    public static func sms(_ messengers: [SMSMessenger.Identifier: SMSMessenger]) -> AnyChannelConfig {
        SMSMessenger.ChannelConfig(messengers: messengers)
    }
}
