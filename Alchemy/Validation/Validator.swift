import Foundation

public struct Validator<Value>: @unchecked Sendable {
    private let message: String?
    private let isValid: (Value) async throws -> Bool

    public init(_ message: String? = nil, isValid: @escaping (Value) async throws -> Bool) {
        self.message = message
        self.isValid = isValid
    }

    public init(_ message: String? = nil, validators: Validator<Value>...) {
        self.message = message
        self.isValid = { value in
            for validator in validators {
                let result = try await validator.isValid(value)
                if !result { return false }
            }

            return true
        }
    }

    public func validate(_ value: Value) async throws {
        guard try await isValid(value) else {
            let message = message ?? "Invalid content."
            throw ValidationError(message)
        }
    }
}

extension Validator<String> {
    public static let email = Validator("Invalid email.") {
        try Regex("[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}")
            .firstMatch(in: $0) != nil
    }
}

extension Validator<Int> {
    public static func between(_ range: ClosedRange<Int>) -> Validator {
        Validator { range.contains($0) }
    }
}
