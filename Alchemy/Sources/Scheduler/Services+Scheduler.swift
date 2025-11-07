/// The appliation Scheduler
public var Schedule: Scheduler {
    Container.scheduler
}

extension Container {
    @Service(.singleton) var scheduler = Scheduler()
}
