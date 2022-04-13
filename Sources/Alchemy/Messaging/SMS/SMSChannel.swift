// MARK: SMSChannel

public struct SMSChannel: Channel {
    public typealias Message = SMSMessage
    public typealias Receiver = SMSReceiver
}

// MARK: SMSMessage

public struct SMSMessage: Codable, Queueable {
    public let text: String
    public var from: String?
    
    public func send<R: SMSReceiver>(to receiver: R, via sender: SMSMessenger = .default) async throws {
        try await sender.send(self, to: receiver)
    }
}

extension SMSMessage: ExpressibleByStringInterpolation {
    public init(stringLiteral value: String) {
        self.init(text: value)
    }
}

// MARK: SMSReceiver

public protocol SMSReceiver {
    var phone: String { get }
}

extension SMSReceiver {
    public func send(sms: SMSMessage, via sender: SMSMessenger = .default) async throws {
        try await sender.send(sms, to: self)
    }
}
