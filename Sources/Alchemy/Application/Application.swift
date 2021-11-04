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
    /// Called before any launch command is run. Called after any
    /// environment is loaded.
    func boot() throws
    
    /// Required empty initializer.
    init()
}
