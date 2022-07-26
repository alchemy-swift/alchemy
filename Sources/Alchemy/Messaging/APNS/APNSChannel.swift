// MARK: APNSChannel

public struct APNSChannel: Channel {
    public typealias Message = APNSMessage
    public typealias Receiver = APNSDevice
}

public struct APNSMessage: Codable {
    public let title: String
    public let body: String
    
    public func send<R: APNSReceiver>(to receiver: R, via sender: APNSMessenger = .default) async throws {
        try await sender.send(self, to: receiver.apnsDevice)
    }
}

extension APNSMessage: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(title: "Alert", body: value)
    }
}

public struct APNSDevice: Codable {
    public let deviceToken: String
}

extension APNSDevice: ExpressibleByStringInterpolation {
    public init(stringLiteral value: String) {
        self.init(deviceToken: value)
    }
}

// MARK: APNSReceiver

public protocol APNSReceiver {
    var deviceToken: String { get }
}

extension APNSReceiver {
    var apnsDevice: APNSDevice {
        APNSDevice(deviceToken: deviceToken)
    }
    
    public func send(push: APNSMessage, via sender: APNSMessenger = .default) async throws {
        try await sender.send(push, to: apnsDevice)
    }
    
    public func send(push title: String, body: String, via sender: APNSMessenger = .default) async throws {
        try await sender.send(APNSMessage(title: title, body: body), to: apnsDevice)
    }
}
