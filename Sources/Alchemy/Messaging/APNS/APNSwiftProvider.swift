struct APNSwiftProvider: ChannelProvider {
    typealias C = APNSChannel
    
    func send(message: APNSMessage, to device: APNSDevice) async throws {
        print("Sending \(message.title) to \(device.deviceToken)!")
    }
}

extension APNSMessenger {
    public static func apnswift(key: String) -> APNSMessenger {
        Messenger(provider: APNSwiftProvider())
    }
}
