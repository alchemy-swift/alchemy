import Alchemy

extension Application {

    /// Configurations related to your app's queues.

    var queues: Queues {
        Queues(

            /// Your app's default Queue.

            default: .redis,

            /// Define your queues here

            queues: [
                .database: .database,
                .memory: .memory,
                .redis: .redis,
            ],

            /// Define any jobs you'll want to handle here

            jobs: [
                GoJob.self
            ]
        )
    }
}

extension Queue.Identifier {
    static var database: Self { "database" }
    static var redis: Self { "redis" }
    static var memory: Self { "memory" }
}
