public func identifier<T>(of metatype: T.Type) -> ObjectIdentifier {
    ObjectIdentifier(metatype)
}

public func name<T>(of metatype: T.Type) -> String {
    "\(metatype)"
}
