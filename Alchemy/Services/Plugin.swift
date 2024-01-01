/// A Plugin represents a modular component of an Alchemy application. They
/// typically inject services into a container that can be used by other
/// plugins and add functionality to an Application once it is loaded.
public protocol Plugin {
    /// A label for this plugin, for registration in the app lifecycle.
    var label: String { get }

    /// Register any services to an Application.
    func registerServices(in app: Application)

    /// Setup this plugin for the given app.
    func boot(app: Application) async throws

    /// Any shutdown logic before services are deallocated from the container.
    func shutdownServices(in app: Application) async throws
}

public extension Plugin {
    var label: String { name(of: Self.self) }
    
    func registerServices(in app: Application) {
        //
    }
    
    func boot(app: Application) async throws {
        //
    }
    
    func shutdownServices(in app: Application) async throws {
        //
    }
    
    internal func register(in app: Application) {
        registerServices(in: app)
        app.lifecycle.register(
            label: label,
            start: .async {
                try await boot(app: app)
            },
            shutdown: .async {
                try await shutdownServices(in: app)
            },
            shutdownIfNotStarted: true
        )
    }
}
