/// Conform a class to `Containerized` lets the `@Inject` property
/// wrapper know that there is a custom container from which
/// services should be resolved.
///
/// If the enclosing type of the property wrapper is not
/// `Containerized`, injected services will be resolved
/// from `Container.default`.
///
/// Usage:
/// ```swift
/// final class UsersController: Containerized {
///     let container = Container()
///
///     // Will be resolved from `self.container` instead of `Container.default`
///     @Inject var database: Database
/// }
/// ```
public protocol Containerized: AnyObject {
    /// The container from which `@Inject`ed services on this type
    /// should be resolved.
    var container: Container { get }
}
