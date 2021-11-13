extension Queue {
    public struct Config {
        public struct JobType {
            private init<J: Job>(_ type: J.Type) {
                JobDecoding.register(type)
            }

            public static func job<J: Job>(_ type: J.Type) -> JobType {
                JobType(type)
            }
        }
        
        let queues: [Identifier: Queue]
        let jobs: [JobType]
        
        public init(queues: [Queue.Identifier : Queue], jobs: [Queue.Config.JobType]) {
            self.queues = queues
            self.jobs = jobs
        }
    }

    public static func configure(using config: Config) {
        config.queues.forEach(Queue.register)
    }
}
