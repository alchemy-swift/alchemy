// MARK: SMSChannel

public struct APNSChannel: Channel {
    public typealias Message = APNSMessage
    public typealias Receiver = APNSReceiver
}

// MARK: SMSMessage

public struct APNSMessage {
    public let body: String
    public var from: String?
    
    public func send<R: APNSReceiver>(to receiver: R, via sender: APNSMessenger = .default) async throws {
        try await sender.send(self, to: receiver)
    }
}

extension APNSMessage: ExpressibleByStringInterpolation {
    public init(stringLiteral value: String) {
        self.init(body: value)
    }
}

// MARK: SMSReceiver

public protocol APNSReceiver {
    var deviceToken: String { get }
}

extension APNSReceiver {
    public func send(push: APNSMessage, via sender: APNSMessenger = .default) async throws {
        try await sender.send(push, to: self)
    }
}
