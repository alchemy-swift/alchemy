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

extension Validate: Codable where T: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }

    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(T.self)
        self.init(wrappedValue: value)
    }
}

extension Validate: LosslessStringConvertible & CustomStringConvertible where T: LosslessStringConvertible {
    public init?(_ description: String) {
        guard let wrappedValue = T(description) else { return nil }
        self.init(wrappedValue: wrappedValue)
    }
    
    public var description: String {
        wrappedValue.description
    }
}
