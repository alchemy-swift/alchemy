/// Gives a unique identifier for a metatype.
///
/// - Parameter metatype: The type to provide a unique identifier for.
/// - Returns: A unique identifier for this type.
public func identifier<T>(of metatype: T.Type) -> ObjectIdentifier {
    ObjectIdentifier(metatype)
}

/// Returns the string name of this type.
///
/// - Parameter metatype: The type to name.
/// - Returns: The name of the type.
public func name<T>(of metatype: T.Type) -> String {
    "\(metatype)"
}
