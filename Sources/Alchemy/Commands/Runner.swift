import Lifecycle

/// An abstraction of what this Alchemy program should do when it
/// launches.
protocol Runner {
    /// Register any tasks to the current lifecyle.
    ///
    /// - Parameter lifecycle: The lifecycle of the program.
    func register(lifecycle: ServiceLifecycle)
}
