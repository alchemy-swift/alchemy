extension Filesystem {
    public struct Config {
        public let disks: [Identifier: Filesystem]
        
        public init(disks: [Identifier : Filesystem]) {
            self.disks = disks
        }
    }

    public static func configure(using config: Config) {
        config.disks.forEach(Filesystem.register)
    }
}
