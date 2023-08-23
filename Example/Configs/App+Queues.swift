import Alchemy

extension Application {

    /// Configurations related to your app's queues.

    var queues2: Queues {
        Queues(

            /// Your app's default Queue.

            default: "database",

            /// Define your queues here

            queues: [
                "database": .database,
                "memory": .memory,
            ],

            /// Define any jobs you'll want to handle here

            jobs: []
        )
    }
}

extension Queue.Identifier {
    static var database: Self { "database" }
    static var redis: Self { "redis" }
    static var memory: Self { "memory" }
}
