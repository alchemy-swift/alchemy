// MARK: SMS

import Fakery

public var SMS: SMSSender { .default }
public func SMS(_ id: SMSSender.Identifier) -> SMSSender { .id(id) }

//public struct SMSSender: Service {
//    public struct Identifier: ServiceIdentifier {
//        private let hashable: AnyHashable
//        public init(hashable: AnyHashable) { self.hashable = hashable }
//    }
//
//    let provider: SMSProvider
//
//    public init(provider: SMSProvider) {
//        self.provider = provider
//    }
//
//    public func send<R: SMSReceiver>(_ message: SMSMessage<R>, to receiver: R) async throws {
//        try await provider.send(message: message.text, to: receiver.phone, from: message.from)
//    }
//
//    public func send(_ message: SMSMessage<SMSPhoneNumber>, to phone: String) async throws {
//        try await send(message, to: SMSPhoneNumber(phone: phone))
//    }
//}

public typealias SMSSender = NotificationSender<SMSChannel>

public struct SMSPhoneNumber: SMSReceiver {
    public let phone: String
}

//public protocol SMSProvider {
//    func send(message: String, to: String, from: String?) async throws
//}

struct TwilioProvider: ChannelProvider {
    typealias C = SMSChannel
    
    func send(message: SMSMessage2, to: SMSReceiver2) async throws {
        // send
    }
}

public struct SMSMessage2 {
    
}

public struct SMSReceiver2 {
    
}

public enum SMSChannel: Channel {
    public typealias Message = SMSMessage2
    public typealias Receiver = SMSReceiver2
}

public protocol Channel {
    associatedtype Message
    associatedtype Receiver
}

public protocol ChannelProvider {
    associatedtype C: Channel
    
    func send(message: C.Message, to: C.Receiver) async throws
}

public struct NotificationSender<C: Channel>: Service {
    public struct Identifier: ServiceIdentifier {
        private let hashable: AnyHashable
        public init(hashable: AnyHashable) { self.hashable = hashable }
    }
    
    let _send: (C.Message, C.Receiver) async throws -> Void
    
    public init<P: ChannelProvider>(provider: P) where P.C == C {
        self._send = provider.send
    }
    
    public func send(message: C.Message, receiver: C.Receiver) async throws {
        try await _send(message, receiver)
    }
}
