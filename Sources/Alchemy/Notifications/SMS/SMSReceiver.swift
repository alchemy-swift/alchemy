public protocol SMSReceiver: Receiver {
    var phone: String { get }
}

extension SMSReceiver {
    public func send(sms: SMSMessage<Self>, via sender: SMSSender = .default) async throws {
        try await sender.send(sms, to: self)
    }
}
