import Alchemy

extension Applications {

    /// Configurations related to your app's filesystems.

    var filesystems: Filesystems {
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
