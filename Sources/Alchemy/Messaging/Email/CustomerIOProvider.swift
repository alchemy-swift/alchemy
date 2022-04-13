struct CustomerIOProvider: ChannelProvider {
    typealias C = EmailChannel
    
    func send(message: EmailMessage, to: EmailReceiver) async throws {
        // send
    }
}

extension EmailMessenger {
    public static func customerio(key: String) -> EmailMessenger {
        Messenger(provider: CustomerIOProvider())
    }
}
