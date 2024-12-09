/// Your app's default Queue
public var Q: Queue {
    Container.main.require(default: .memory)
}

public func Q(_ key: KeyPath<Container, Queue>) -> Queue {
    Container.main[keyPath: key]
}

/// Job registration.
var Jobs: JobRegistry {
    Container.$jobRegistry
}

extension Container {
    @Singleton var jobRegistry = JobRegistry()
}

extension Application {
    public func setDefaultQueue(_ key: KeyPath<Container, Queue>) {
        Container.main.setAlias(key)
    }

    /// Registers a job to be handled by your application. If you don't register
    /// a job type, `Queue` workers won't be able to handle jobs of that type.
    public func registerJob(_ jobType: Job.Type) {
        Jobs.register(jobType)
    }

    public func registerJobs() {
        for job in jobs {
            registerJob(job)
        }
    }
}
