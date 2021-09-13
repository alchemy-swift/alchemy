/// The core type for an Alchemy application. Implement this & it's
/// `boot` function, then add the `@main` attribute to mark it as
/// the entrypoint for your application.
///
/// ```swift
/// @main
/// struct App: Application {
///     func boot() {
///         get("/hello") { _ in
///             "Hello, world!"
///         }
///         ...
///     }
/// }
/// ```
public protocol Application {
    /// Called before any launch command is run. Called AFTER any
    /// environment is loaded and the global `EventLoopGroup` is
    /// set. Called on an event loop, so `Loop.current` is
    /// available for use if needed.
    func boot() throws
    
    /// Required empty initializer.
    init()
}
