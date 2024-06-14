@propertyWrapper
public struct Validate<T> {
    public var wrappedValue: T
    public var projectedValue: Validate<T> { self }

    private let validators: [Validator<T>]

    public init(wrappedValue: T, _ validators: Validator<T>...) {
        self.wrappedValue = wrappedValue
        self.validators = validators
    }

    public func validate() async throws {
        for validator in validators {
            try await validator.validate(wrappedValue)
        }
    }
}
