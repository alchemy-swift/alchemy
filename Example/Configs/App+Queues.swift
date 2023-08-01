import Alchemy

extension Plugin where Self == Queues {

    /// Configurations related to your app's queues.

    static var queues: Queues {
        Queues(

            /// Define your queues here

            queues: [
                .default: .database,
                .memory: .memory,
            ],

            /// Define any jobs you'll want to handle here

            jobs: []
        )
    }
}

extension Queue.Identifier {
    static var redis: Self { "redis" }
    static var memory: Self { "memory" }
}
