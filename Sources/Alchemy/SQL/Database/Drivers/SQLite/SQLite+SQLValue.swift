import SQLiteNIO

extension SQLiteData: SQLValueConvertible {
    /// Initialize from an Alchemy `SQLValue`.
    ///
    /// - Parameter value: the value with which to initialize. Given
    ///   the type of the value, the `SQLiteData` will be
    ///   initialized with the best corresponding type.
    init(_ value: SQLValue) {
        struct Formatters {
            static let iso8601DateFormatter = ISO8601DateFormatter()
        }

        switch value {
        case .bool(let value):
            self = value ? .integer(1) : .integer(0)
        case .date(let value):
            self = .text(Formatters.iso8601DateFormatter.string(from: value))
        case .double(let value):
            self = .float(value)
        case .int(let value):
            self = .integer(value)
        case .json(let value):
            self = .text(value.string)
        case .bytes(let value):
            self = .blob(value)
        case .string(let value):
            self = .text(value)
        case .uuid(let value):
            self = .text(value.uuidString)
        case .null:
            self = .null
        }
    }

    // MARK: SQLValueConvertible

    public var sqlValue: SQLValue {
        switch self {
        case .integer(let int):
            return .int(int)
        case .float(let double):
            return .double(double)
        case .text(let string):
            return .string(string)
        case .blob(let bytes):
            return .bytes(bytes)
        case .null:
            return .null
        }
    }
}
