// MARK: SMSChannel

public struct SlackChannel: Channel {
    public typealias Message = SlackMessage
    public typealias Receiver = SlackHook
}

// MARK: SMSMessage

public struct SlackMessage: Codable {
    public let text: String
    
    public func send<R: SlackReceiver>(to receiver: R, via sender: SlackMessenger = .default) async throws {
        try await sender.send(self, to: receiver.hook)
    }
}

extension SlackMessage: ExpressibleByStringInterpolation {
    public init(stringLiteral value: String) {
        self.init(text: value)
    }
}

public struct SlackHook: Codable {
    public let url: String
    
    public init(url: String) {
        self.url = url
    }
}

extension SlackHook: ExpressibleByStringInterpolation {
    public init(stringLiteral value: String) {
        self.init(url: value)
    }
}

// MARK: SMSReceiver

public protocol SlackReceiver {
    var hookURL: String { get }
}

extension SlackReceiver {
    public var hook: SlackHook {
        SlackHook(url: hookURL)
    }
    
    public func send(slack: SlackMessage, via sender: SlackMessenger = .default) async throws {
        try await sender.send(slack, to: hook)
    }
}
