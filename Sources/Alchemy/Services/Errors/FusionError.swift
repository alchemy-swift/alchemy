public enum FusionError: Error {
    /// A factory was not registered for the given type and identifier.
    case notRegistered(type: Any.Type, id: AnyHashable?)
}
