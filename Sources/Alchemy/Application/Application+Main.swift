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
        Env.boot()
        
        do {
            let app = Self()
            app.bootServices()
            try app.boot()
            Launch.main()
            try ServiceLifecycle.default.startAndWait()
        } catch {
            Launch.exit(withError: error)
        }
    }
}
