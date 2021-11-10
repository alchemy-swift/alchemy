import NIO

protocol ServerUpgrade {
    func upgrade(channel: Channel) async throws
}
