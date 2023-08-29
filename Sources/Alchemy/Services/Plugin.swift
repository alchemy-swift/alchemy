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

extension Plugin {
    public var label: String { name(of: Self.self) }
    public func registerServices(in app: Application) { /* default to no-op */ }
    public func boot(app: Application) async throws { /* default to no-op */ }
    public func shutdownServices(in app: Application) async throws { /* default to no-op */ }
}
