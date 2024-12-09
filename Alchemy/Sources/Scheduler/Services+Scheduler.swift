/// The appliation Scheduler
public var Schedule: Scheduler {
    Container.$scheduler
}

extension Container {
    @Singleton var scheduler = Scheduler()
}
