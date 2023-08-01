struct SchedulingPlugin: Plugin {
    func registerServices(in container: Container) {
        container.bind(.singleton, value: Scheduler())
    }
}
