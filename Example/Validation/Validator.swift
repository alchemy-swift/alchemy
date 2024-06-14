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
        self.isValid = { _ in fatalError() }
    }

    public func validate(_ value: Value) async throws {
        guard try await isValid(value) else {
            let message = message ?? "Invalid content."
            throw ValidationError.invalid(message)
        }
    }
}

public enum ValidationError: Error {
    case invalid(String)
}

extension Validator<String> {
    public static let username = Validator(validators: .profanity, .email)
    public static let profanity = Validator { $0 != "dang" }

    public static let email = Validator {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: $0)
    }

    public static let password = Validator {
        $0.count > 8 &&
        $0.rangeOfCharacter(from: .decimalDigits) != nil &&
        $0.rangeOfCharacter(from: .alphanumerics.inverted) != nil
    }

    public static let fraud = Validator {
        try await Task.sleep(for: .seconds(1))
        return $0 != "fraudman101@fraud.com"
    }
}

extension Validator<Int> {
    public static func between(_ range: ClosedRange<Int>) -> Validator {
        Validator { range.contains($0) }
    }
}
