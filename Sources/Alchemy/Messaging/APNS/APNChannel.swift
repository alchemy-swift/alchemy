// MARK: SMSChannel

public struct APNSChannel: Channel {
    public typealias Message = APNMessage
    public typealias Receiver = APNDevice
}

// MARK: APNSMessage

public struct APNMessage: Codable, Queueable {
    public let title: String
    public let body: String
    
    public func send<R: APNReceiver>(to receiver: R, via sender: APNMessenger = .default) async throws {
        try await sender.send(self, to: receiver.device)
    }
}

public struct APNDevice: Codable {
    public let deviceToken: String
}

// MARK: APNSReceiver

public protocol APNReceiver {
    var deviceToken: String { get }
}

extension APNReceiver {
    var device: APNDevice { APNDevice(deviceToken: deviceToken) }
}

extension APNReceiver {
    public func send(push: APNMessage, via sender: APNMessenger = .default) async throws {
        try await sender.send(push, to: device)
    }
    
    public func send(pushTitle: String, body: String, via sender: APNMessenger = .default) async throws {
        try await sender.send(APNMessage(title: pushTitle, body: body), to: device)
    }
}
