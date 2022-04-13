// MARK: SMS

public var SMS: SMSSender { .default }
public func SMS(_ id: SMSSender.Identifier) -> SMSSender { .id(id) }

public struct SMSSender: Service {
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

//public protocol SMSProvider {
//    func send(message: String, to: String, from: String?) async throws
//}

public protocol SMSProvider: ChannelProvider where M == SMSMessage<R>, R: SMSReceiver {}

struct TwilioProvider<R: SMSReceiver>: SMSProvider {
    func send(message: SMSMessage<R>, receiver: R) async throws {
        // send
    }
}

public protocol ChannelProvider {
    associatedtype M: Message
    associatedtype R: Receiver
    
    func send(message: M, receiver: R) async throws
}

public protocol NotificationChannel {
    associatedtype Provider: ChannelProvider
}

public struct NotificationSender<Channel: NotificationChannel>: Service {
    public struct Identifier: ServiceIdentifier {
        private let hashable: AnyHashable
        public init(hashable: AnyHashable) { self.hashable = hashable }
    }
    
    let provider: Channel.Provider
    
    public init(provider: Channel.Provider) {
        self.provider = provider
    }
    
    public func send(message: Channel.Provider.M, receiver: Channel.Provider.R) async throws {
        try await provider.send(message: message, receiver: receiver)
    }
}

extension NotificationSender where Channel.Provider: SMSProvider {
    
}
