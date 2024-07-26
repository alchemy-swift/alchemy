struct Schedules: Plugin {
    let scheduler = Scheduler()

    func boot(app: Application) {
        app.container.register(scheduler).singleton()
        app.registerCommand(ScheduleCommand.self)
    }
}
