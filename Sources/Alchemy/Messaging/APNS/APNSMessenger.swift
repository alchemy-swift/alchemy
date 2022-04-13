// MARK: Aliases

public var APNS: APNSMessenger { .default }
public func APNS(_ id: APNSMessenger.Identifier) -> APNSMessenger { .id(id) }

// MARK: SMSMessenger

public typealias APNSMessenger = Messenger<APNSChannel>

extension APNSMessenger {
    private struct _OneOffReceiver: APNSReceiver {
        let deviceToken: String
    }
    
    public func send(_ message: APNSMessage, toDeviceToken: String) async throws {
        try await send(message, to: _OneOffReceiver(deviceToken: toDeviceToken))
    }
}

// MARK: Config + APNS

extension AnyChannelConfig where Self == APNSMessenger.ChannelConfig {
    static func apns(_ messengers: [APNSMessenger.Identifier: APNSMessenger]) -> AnyChannelConfig {
        APNSMessenger.ChannelConfig(messengers: messengers)
    }
}
