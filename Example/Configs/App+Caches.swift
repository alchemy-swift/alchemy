import Alchemy

extension Plugin where Self == Caches {
    static var caches: Caches {
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
