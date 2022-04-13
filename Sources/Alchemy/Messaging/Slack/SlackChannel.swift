// MARK: SMSChannel

public struct SlackChannel: Channel {
    public typealias Message = SlackMessage
    public typealias Receiver = SlackReceiver
}

// MARK: SMSMessage

public struct SlackMessage: Codable, Queueable {
    public let text: String
    public var from: String?
    
    public func send<R: SlackReceiver>(to receiver: R, via sender: SlackMessenger = .default) async throws {
        try await sender.send(self, to: receiver)
    }
}

extension SlackMessage: ExpressibleByStringInterpolation {
    public init(stringLiteral value: String) {
        self.init(text: value)
    }
}

// MARK: SMSReceiver

public protocol SlackReceiver {
    var hook: String { get }
}

extension SlackReceiver {
    public func send(slack: SlackMessage, via sender: SlackMessenger = .default) async throws {
        try await sender.send(slack, to: self)
    }
}
