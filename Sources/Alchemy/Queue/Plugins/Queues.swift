public struct Queues: Plugin {
    public let `default`: Queue.Identifier?
    public let queues: () -> [Queue.Identifier: Queue]
    public let jobs: [Job.Type]

    public init(default: Queue.Identifier? = nil, queues: @escaping @autoclosure () -> [Queue.Identifier : Queue] = [:], jobs: [Job.Type] = []) {
        self.default = `default`
        self.queues = queues
        self.jobs = jobs
    }

    public func registerServices(in app: Application) {
        let queues = queues()
        for (id, queue) in queues {
            app.container.register(queue, id: id).singleton()
        }

        if let _default = `default` ?? queues.keys.first {
            app.container.register(Q(_default)).singleton()
        }

        for job in jobs {
            app.registerJob(job)
        }
    }

    public func boot(app: Application) {
        app.registerCommand(WorkCommand.self)
    }

    public func shutdownServices(in app: Application) async throws {
        JobRegistry.reset()
    }
}
