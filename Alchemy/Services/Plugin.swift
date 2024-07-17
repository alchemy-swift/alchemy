/// A Plugin represents a modular component of an Alchemy application.
public protocol Plugin {
    /// Start this plugin given an app.
    func boot(app: Application) async throws

    /// Shutdown the plugin that was booted on the given app.
    func shutdown(app: Application) async throws
}

extension Plugin {
    public func shutdown(app: Application) async throws {}
}
