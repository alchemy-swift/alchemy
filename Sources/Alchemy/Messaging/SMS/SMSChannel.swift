// MARK: SMSChannel

public struct SMSChannel: Channel {
    public typealias Message = SMSMessage
    public typealias Receiver = SMSDevice
}

// MARK: SMSMessage

public struct SMSMessage: Codable {
    public let text: String
    public var from: String?
    
    public func send<R: SMSReceiver>(to receiver: R, via sender: SMSMessenger = .default) async throws {
        try await sender.send(self, to: receiver.smsDevice)
    }
}

extension SMSMessage: ExpressibleByStringInterpolation {
    public init(stringLiteral value: String) {
        self.init(text: value)
    }
}

public struct SMSDevice: Codable {
    public let number: String
    
    public init(number: String) {
        self.number = number
    }
}

extension SMSDevice: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.number = value
    }
}

// MARK: SMSReceiver

public protocol SMSReceiver {
    var phone: String { get }
}

extension SMSReceiver {
    var smsDevice: SMSDevice {
        SMSDevice(number: phone)
    }
    
    public func send(sms: SMSMessage, via sender: SMSMessenger = .default) async throws {
        try await sender.send(sms, to: smsDevice)
    }
}
