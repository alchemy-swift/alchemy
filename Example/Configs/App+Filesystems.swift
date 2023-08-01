import Alchemy

extension Plugin where Self == Filesystems {
    static var filesystems: Filesystems {
        Filesystems(

            /// Define your filesystem disks here.

            disks: [
                .default: .local
            ]
        )
    }
}
