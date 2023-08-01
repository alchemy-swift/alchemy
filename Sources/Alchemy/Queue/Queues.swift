public struct Queues: Plugin {
    public let queues: [Queue.Identifier: Queue]
    public let jobs: [Job.Type]

    public init(queues: [Queue.Identifier : Queue], jobs: [Job.Type]) {
        self.queues = queues
        self.jobs = jobs
    }

    public func registerServices(in container: Container) {
        for (id, queue) in queues {
            container.registerSingleton(queue, id: id)
        }

        for job in jobs {
            JobDecoding.register(job)
        }
    }

    public func boot(app: Application) {
        app.registerCommand(WorkCommand.self)
    }
}
