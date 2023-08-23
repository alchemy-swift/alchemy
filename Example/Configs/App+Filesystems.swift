import Alchemy

extension Plugin where Self == Filesystems {
    static var filesystems: Filesystems {
        Filesystems(

            /// Your app's default filesystem.

            default: "local",

            /// Define your filesystem disks here.

            disks: [
                "local": .local
            ]
        )
    }
}
