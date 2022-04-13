// MARK: SMS

public var SMS: Notifier<SMSChannel> { .default }
public func SMS(_ id: Notifier<SMSChannel>.Identifier) -> Notifier<SMSChannel> { .id(id) }

public enum SMSChannel<Receiver: SMSReceiver>: Channel {
    public typealias Message = SMSMessage
}

protocol Channel {
    associatedtype M: Message
    associatedtype R where M.R == R
}

public typealias SMSSender = Notifier<SMSChannel>

public struct Notifier<C: Channel>: Service {
    public struct Identifier: ServiceIdentifier {
        private let hashable: AnyHashable
        public init(hashable: AnyHashable) { self.hashable = hashable }
    }
    
    let provider: SMSProvider
    
    public init(provider: SMSProvider) {
        self.provider = provider
    }
    
    public func send<R: SMSReceiver>(_ message: SMSMessage<R>, to receiver: R) async throws {
        try await provider.send(message: message.text, to: receiver.phone, from: message.from)
    }
    
    public func send(_ message: SMSMessage<SMSPhoneNumber>, to phone: String) async throws {
        try await send(message, to: SMSPhoneNumber(phone: phone))
    }
}

public struct SMSPhoneNumber: SMSReceiver {
    public let phone: String
}

public protocol SMSProvider {
    func send(message: String, to: String, from: String?) async throws
}
