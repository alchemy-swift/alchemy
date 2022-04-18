struct APNSwiftProvider: ChannelProvider {
    typealias C = APNSChannel
    
    func send(message: APNMessage, to device: APNDevice) async throws {
        print("Sending \(message.title) to \(device.deviceToken)!")
    }
}

extension APNMessenger {
    public static func apnswift(key: String, saveInDatabase: Bool = false, preferQueueing: Bool = false) -> APNMessenger {
        Messenger(provider: APNSwiftProvider(), saveInDatabase: saveInDatabase, preferQueueing: preferQueueing)
    }
}
