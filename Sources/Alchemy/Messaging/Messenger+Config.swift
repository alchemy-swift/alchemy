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

public protocol AnyChannelConfig {
    func bind()
}

extension Messenger: Configurable {
    public static var config: Config {
        Config(
            channels: [
                
                /// Put your SMS configs here
                
                .sms([
                    .default: .twilio(key: "foo")
                ]),
                
                /// Put your email configs here
            
                .email([
                    .default: .customerio(key: "foo")
                ]),

                /// Put your database configs here
                    
                .apns([
                    .default: .apnswift(key: "foo")
                ]),
            ])
    }
}
