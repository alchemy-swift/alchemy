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
        let app = Self()
        do { try app.setup() }
        catch { Launch.exit(withError: error) }
        app.start()
        app.wait()
    }
    
    public func start(_ args: String..., didStart: @escaping (Error?) -> Void = defaultErrorHandler) {
        if args.isEmpty {
            start(didStart: didStart)
        } else {
            start(args: args, didStart: didStart)
        }
    }
    
    public static func defaultErrorHandler(error: Error?) {
        if let error = error {
            Launch.exit(withError: error)
        }
    }
    
    public func start(args: [String] = Array(CommandLine.arguments.dropFirst()), didStart: @escaping (Error?) -> Void = defaultErrorHandler) {
        Launch.main(args.isEmpty ? nil : args)
        Container.resolve(ServiceLifecycle.self).start(didStart)
    }
    
    public func wait() {
        Container.resolve(ServiceLifecycle.self).wait()
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
