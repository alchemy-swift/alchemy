import Alchemy

extension Queue: Configurable {
    
    /// Configurations related to your app's queues.
    
    public static var config = Config(
        
        /// Define your queues here
        
        queues: [
            .default: .database,
//            .redis: .redis,
            .memory: .memory,
        ],
        
        /// Define any jobs you'll want to handle here
        
        jobs: []
    )
}

extension Queue.Identifier {
    static var redis: Self { "redis" }
    static var memory: Self { "memory" }
}
