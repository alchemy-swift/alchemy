/// Returns the string name of this type.
///
/// - Parameter metatype: The type to name.
/// - Returns: The name of the type.
public func name<T>(of metatype: T.Type) -> String {
    "\(metatype)"
}
