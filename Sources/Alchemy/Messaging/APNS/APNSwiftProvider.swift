struct APNSwiftProvider: ChannelProvider {
    typealias C = APNSChannel
    
    func send(message: APNSMessage, to: APNSReceiver) async throws {
        // send
    }
}

extension APNSMessenger {
    public static func apnswift(key: String, saveInDatabase: Bool = false) -> APNSMessenger {
        Messenger(provider: APNSwiftProvider(), saveInDatabase: saveInDatabase)
    }
}
