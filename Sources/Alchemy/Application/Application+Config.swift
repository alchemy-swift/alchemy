import Hummingbird

extension Application {
    public typealias Configuration = ApplicationConfiguration
}

public struct ApplicationConfiguration {
    public let plugins: [Plugin]
    public let commands: [Command.Type]
    public let hbConfiguration: HBApplication.Configuration

    public init(
        plugins: [Plugin] = [],
        commands: [Command.Type] = [],
        hbConfiguration: HBApplication.Configuration = .init(logLevel: .notice)
    ) {
        self.plugins = plugins
        self.commands = commands
        self.hbConfiguration = hbConfiguration
    }
}
