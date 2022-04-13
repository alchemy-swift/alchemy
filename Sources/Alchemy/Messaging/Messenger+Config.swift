public protocol AnyChannelConfig {
    func bind()
}

extension Messenger {
    public struct ChannelConfig: AnyChannelConfig {
        let messengers: [Messenger<C>.Identifier: Messenger<C>]
        
        public func bind() {
            messengers.forEach { Messenger.bind($0, $1) }
        }
    }
    
    public struct Config {
        public let channels: [AnyChannelConfig]
        
        public init(channels: [AnyChannelConfig]) {
            self.channels = channels
        }
    }

    public static func configure(with config: Config) {
        config.channels.forEach { $0.bind() }
    }
}

extension AnyChannelConfig where Self == SMSMessenger.ChannelConfig {
    static func sms(_ messengers: [SMSMessenger.Identifier: SMSMessenger]) -> AnyChannelConfig {
        SMSMessenger.ChannelConfig(messengers: messengers)
    }
}

extension Messenger: Configurable {
    public static var config: Config {
        Config(channels: [
            .sms([
                .default: .twilio(key: "foo")
            ]),
        ])
    }
}
