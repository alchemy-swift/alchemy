// MARK: Aliases

public var APNS: APNSMessenger { .default }
public func APNS(_ id: APNSMessenger.Identifier) -> APNSMessenger { .id(id) }

// MARK: SMSMessenger

public typealias APNSMessenger = Messenger<APNSChannel>

extension APNSMessenger {
    public func send(_ message: APNSMessage, toDeviceToken token: String) async throws {
        try await send(message, to: APNSDevice(deviceToken: token))
    }
    
    public func send(title: String, body: String, to receiver: APNSReceiver) async throws {
        try await send(APNSMessage(title: title, body: body), to: receiver.apnsDevice)
    }
}

// MARK: Config + APNS

extension AnyChannelConfig where Self == APNSMessenger.ChannelConfig {
    public static func apns(_ messengers: [APNSMessenger.Identifier: APNSMessenger]) -> AnyChannelConfig {
        APNSMessenger.ChannelConfig(messengers: messengers)
    }
}
