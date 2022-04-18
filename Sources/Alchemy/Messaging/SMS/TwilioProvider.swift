struct TwilioProvider: ChannelProvider {
    typealias C = SMSChannel
    
    func send(message: SMSMessage, to: SMSReceiver) async throws {
        // send
    }
}

extension SMSMessenger {
//    public static func twilio(key: String, saveInDatabase: Bool = false) -> SMSMessenger {
//        Messenger(provider: TwilioProvider(), saveInDatabase: saveInDatabase)
//    }
}
