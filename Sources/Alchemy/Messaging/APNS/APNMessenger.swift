// MARK: Aliases

public var APNS: APNMessenger { .default }
public func APNS(_ id: APNMessenger.Identifier) -> APNMessenger { .id(id) }

// MARK: SMSMessenger

public typealias APNMessenger = Messenger<APNSChannel>

extension APNMessenger {
    public func send(_ message: APNMessage, toDeviceToken token: String) async throws {
        try await send(message, to: APNDevice(deviceToken: token))
    }
    
    public func send(title: String, body: String, to receiver: APNReceiver) async throws {
        try await send(APNMessage(title: title, body: body), to: receiver.device)
    }
}

// MARK: Config + APNS

extension AnyChannelConfig where Self == APNMessenger.ChannelConfig {
    public static func apns(_ messengers: [APNMessenger.Identifier: APNMessenger]) -> AnyChannelConfig {
        APNMessenger.ChannelConfig(messengers: messengers)
    }
}
