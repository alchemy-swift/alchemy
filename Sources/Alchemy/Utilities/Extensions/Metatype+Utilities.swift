/// Returns the string name of this type.
///
/// - Parameter metatype: The type to name.
/// - Returns: The name of the type.
public func name<T>(of metatype: T.Type) -> String {
    "\(metatype)"
}

/// Returns an id for the given type.
///
/// - Parameter metatype: The type to identify.
/// - Returns: A unique id for the type.
public func id(of metatype: Any.Type) -> ObjectIdentifier {
    ObjectIdentifier(metatype)
}
