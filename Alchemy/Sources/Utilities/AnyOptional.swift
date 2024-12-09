protocol AnyOptional {
    static var wrappedType: Any.Type { get }
    static var nilValue: Self { get }
}

extension Optional: AnyOptional {
    static var wrappedType: Any.Type { Wrapped.self }
    static var nilValue: Self { nil}
}
