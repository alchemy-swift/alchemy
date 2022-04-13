struct APNSwiftProvider: ChannelProvider {
    typealias C = APNSChannel
    
    func send(message: APNSMessage, to: APNSReceiver) async throws {
        // send
    }
}

extension APNSMessenger {
    public static func apnswift(key: String) -> APNSMessenger {
        Messenger(provider: APNSwiftProvider())
    }
}
