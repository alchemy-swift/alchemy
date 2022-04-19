import APNSwift
import JWTKit

extension APNSMessenger {
    public static func apnswift(config: APNSwiftConfiguration) -> APNSMessenger {
        Messenger(provider: APNSwiftProvider(config: config))
    }
    
    public static func apnswift(keyfilePath: String, keyIdentifier: String, teamIdentifier: String, topic: String, environment: APNSwiftConfiguration.Environment) -> APNSMessenger {
        do {
            return Messenger(
                provider: APNSwiftProvider(
                    config: APNSwiftConfiguration(
                        authenticationMethod: .jwt(
                            key: try .private(filePath: keyfilePath),
                            keyIdentifier: JWKIdentifier(string: keyIdentifier),
                            teamIdentifier: teamIdentifier
                        ),
                        topic: topic,
                        environment: environment
                    )
                )
            )
        } catch {
            preconditionFailure("Error creating APNs configuration \(error)! Perhaps there isn't a file at the given path?")
        }
    }
}

private struct APNSwiftProvider: ChannelProvider {
    typealias C = APNSChannel
    
    fileprivate let config: APNSwiftConfiguration
    
    func send(message: APNSMessage, to device: APNSDevice) async throws {
        let connection = try await APNSwiftConnection.connect(configuration: config, on: Loop.current).get()
        let alert = APNSwiftAlert(title: message.title, body: message.body)
        let payload = APNSwiftPayload(alert: alert)
        try await connection.send(payload, pushType: .alert, to: device.deviceToken).get()
        try await connection.close().get()
    }
}
