struct CustomerIOProvider: ChannelProvider {
    typealias C = EmailChannel
    
    func send(message: EmailMessage, to: EmailReceiver) async throws {
        // send
    }
}

extension EmailMessenger {
    public static func customerio(key: String, saveInDatabase: Bool = false) -> EmailMessenger {
        Messenger(provider: CustomerIOProvider(), saveInDatabase: saveInDatabase)
    }
}
