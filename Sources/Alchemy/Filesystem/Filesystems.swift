public struct Filesystems: Plugin {
    public let disks: [Filesystem.Identifier: Filesystem]

    public init(disks: [Filesystem.Identifier: Filesystem]) {
        self.disks = disks
    }

    public func registerServices(in container: Container) {
        for (id, disk) in disks {
            container.registerSingleton(disk, id: id)
        }
    }
}
