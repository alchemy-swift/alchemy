extension Application {
    /// Registers a job to be handled by your application. If you
    /// don't register a job type, `QueueWorker`s won't be able
    /// to handle jobs of that type.
    ///
    /// - Parameter jobType: The type of Job to register.
    public func registerJob(_ jobType: Job.Type) {
        JobRegistry.register(jobType)
    }
}
