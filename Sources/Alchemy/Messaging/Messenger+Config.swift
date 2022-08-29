extension Messenger {
    public struct ChannelConfig: AnyChannelConfig {
        public let messengers: [Messenger<C>.Identifier: Messenger<C>]

        public init(messengers: [Messenger<C>.Identifier : Messenger<C>]) {
            self.messengers = messengers
        }
        
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

public protocol AnyChannelConfig {
    func bind()
}
