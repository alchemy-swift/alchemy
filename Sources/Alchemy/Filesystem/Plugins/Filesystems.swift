public struct Filesystems: Plugin {
    public let `default`: Filesystem.Identifier?
    public let disks: [Filesystem.Identifier: Filesystem]

    public init(`default`: Filesystem.Identifier? = nil, disks: [Filesystem.Identifier: Filesystem] = [:]) {
        self.default = `default`
        self.disks = disks
    }

    public func registerServices(in app: Application) {
        for (id, disk) in disks {
            app.container.registerSingleton(disk, id: id)
        }

        if let _default = `default` ?? disks.keys.first {
            app.container.registerSingleton(Storage(_default))
        }
    }
}
