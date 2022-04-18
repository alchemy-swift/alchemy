// MARK: SMSChannel

public struct APNSChannel: Channel {
    public typealias Message = APNSMessage
    public typealias Receiver = APNSDevice
}

// MARK: APNSMessage

public struct APNSMessage: Codable, Queueable {
    public let title: String
    public let body: String
    
    public func send<R: APNSReceiver>(to receiver: R, via sender: APNSMessenger = .default) async throws {
        try await sender.send(self, to: receiver.device)
    }
}

public struct APNSDevice: Codable {
    public let deviceToken: String
}

// MARK: APNSReceiver

public protocol APNSReceiver {
    var deviceToken: String { get }
}

extension APNSReceiver {
    var device: APNSDevice { APNSDevice(deviceToken: deviceToken) }
}

extension APNSReceiver {
    public func send(push: APNSMessage, via sender: APNSMessenger = .default) async throws {
        try await sender.send(push, to: device)
    }
    
    public func send(push title: String, body: String, via sender: APNSMessenger = .default) async throws {
        try await sender.send(APNSMessage(title: title, body: body), to: device)
    }
}
