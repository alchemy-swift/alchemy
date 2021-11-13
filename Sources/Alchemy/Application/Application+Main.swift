import Lifecycle
import LifecycleNIOCompat

extension Application {
    /// Lifecycle logs quite a bit by default, this quiets it's `info`
    /// level logs. To output messages lower than `notice`, you may
    /// override this property to `.info` or lower.
    public var lifecycleLogLevel: Logger.Level { .notice }
    
    /// Launch this application. By default it serves, see `Launch`
    /// for subcommands and options. Call this in the `main.swift`
    /// of your project.
    public static func main() {
        do {
            try Self().setup()
            Launch.main()
            try Container.resolve(ServiceLifecycle.self).startAndWait()
        } catch {
            Launch.exit(withError: error)
        }
    }
    
    /// Sets up this application for running.
    func setup(testing: Bool = false) throws {
        Env.boot()
        bootServices(testing: testing)
        services(container: .default)
        schedule(schedule: .default)
        try boot()
        Launch.customCommands.append(contentsOf: commands)
        Container.register(singleton: self)
    }
}
