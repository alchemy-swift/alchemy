public struct Filesystems: Plugin {
    public let `default`: Filesystem.Identifier?
    public let disks: [Filesystem.Identifier: Filesystem]

    public init(`default`: Filesystem.Identifier? = nil, disks: [Filesystem.Identifier: Filesystem] = [:]) {
        self.default = `default`
        self.disks = disks
    }

    public func boot(app: Application) {
        for (id, disk) in disks {
            app.container.register(disk, id: id).singleton()
        }

        if let _default = `default` ?? disks.keys.first {
            app.container.register(Storage(_default)).singleton()
        }
    }
}
