import Alchemy

extension Application {
    var caches: Caches {
        Caches(

            /// Your app's default Cache

            default: "database",

            /// Define your caches here

            caches: [
                "database": .database
            ]
        )
    }
}
