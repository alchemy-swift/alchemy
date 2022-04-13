public struct SMSMessage<R: SMSReceiver>: Message {
    public let text: String
    public var from: String?
    
    public func send(to receiver: R, via sender: SMSSender) async throws {
        try await sender.send(self, to: receiver)
    }
}

extension SMSMessage: ExpressibleByStringInterpolation {
    public init(stringLiteral value: String) {
        self.init(text: value)
    }
}
