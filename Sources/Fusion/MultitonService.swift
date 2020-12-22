/// A `MultitonService` is like a single instances except that it has multiple instances, each tied
/// to an identifier.
public protocol MultitonService {
    associatedtype Identifier: Hashable
}

extension Inject where Service: MultitonService {
    /// A convience `init` for `@Inject`ing a `MultitonService` via property wrapper.
    ///
    /// Usage:
    /// ```
    /// enum LoggerType: String {
    ///     case remote
    ///     case local
    /// }
    ///
    /// protocol Logger: MultitonService {
    ///     typealias Identifier = LoggerType
    ///
    ///     ...
    /// }
    ///
    /// Container.global.register(multiton: Logger.self) { container, identifier in
    ///     switch identifier {
    ///     case .remote:
    ///         return RemoteLogger(...)
    ///     case .local:
    ///         return LocalLogger(...)
    ///     }
    /// }
    ///
    /// struct SomeType {
    ///     @Inject(.remote) var remoteLogger: Logger
    /// }
    /// ```
    ///
    /// - Parameter identifier: the identifier of the `MultitonService` to inject.
    public convenience init(_ identifier: Service.Identifier) {
        self.init()
        self.identifier = AnyHashable(identifier)
    }
}
