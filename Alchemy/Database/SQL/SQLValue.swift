/// A value that can be stored and loaded from fields in an SQL table.
public enum SQLValue: Hashable, CustomStringConvertible {
    /// An `Int` value.
    case int(Int)
    /// A `Double` value.
    case double(Double)
    /// A `Bool` value.
    case bool(Bool)
    /// A `String` value.
    case string(String)
    /// A `Date` value.
    case date(Date)
    /// A JSON value, given as a `ByteBuffer`.
    case json(ByteBuffer)
    /// A type for raw bytes.
    case bytes(ByteBuffer)
    /// A `UUID` value.
    case uuid(UUID)
    /// A null value of any type.
    case null

    public static func json(_ string: String) -> SQLValue {
        .json(ByteBuffer(string: string))
    }

    public var rawSQLString: String {
        switch self {
        case .int(let int):
            return "\(int)"
        case .double(let double):
            return "\(double)"
        case .bool(let bool):
            return "\(bool)"
        case .string(let string):
            return "'\(string)'"
        case .date(let date):
            return "\(date)"
        case .json(let bytes), .bytes(let bytes):
            return bytes.string
        case .uuid(let uuid):
            return "\(uuid.uuidString)"
        case .null:
            return "NULL"
        }
    }

    public var description: String {
        rawSQLString
    }

    // MARK: Coercion

    /// Detect if this value is null.
    public func isNull() -> Bool {
        self == .null
    }

    /// Coerce this value to an `Int` or throw an error.
    public func int(_ columnName: String? = nil) throws -> Int {
        switch self {
        case .int(let value):
            return value
        case .date(let value):
            return Int(value.timeIntervalSince1970)
        case .null:
            throw nullError(columnName)
        default:
            throw typeError("Int", columnName: columnName)
        }
    }

    /// Coerce this value to a `String` or throw an error.
    public func string(_ columnName: String? = nil) throws -> String {
        switch self {
        case .string(let value):
            return value
        case .double(let value):
            return String(value)
        case .int(let value):
            return String(value)
        case .bool(let value):
            return String(value)
        case .date(let value):
            return value.description
        case .uuid(let value):
            return value.uuidString
        case .json(let bytes):
            return bytes.string
        case .null:
            throw nullError(columnName)
        default:
            throw typeError("String", columnName: columnName)
        }
    }

    /// Coerce this value to a `Double` or throw an error.
    public func double(_ columnName: String? = nil) throws -> Double {
        switch self {
        case .double(let value):
            return value
        case .int(let value):
            return Double(value)
        case .date(let value):
            return value.timeIntervalSince1970
        case .null:
            throw nullError(columnName)
        default:
            throw typeError("Double", columnName: columnName)
        }
    }

    /// Coerce this value to a `Bool` or throw an error.
    public func bool(_ columnName: String? = nil) throws -> Bool {
        switch self {
        case .bool(let value):
            return value
        case .int(let value):
            return value != 0
        case .double(let value):
            return value != 0.0
        case .null:
            throw nullError(columnName)
        default:
            throw typeError("Bool", columnName: columnName)
        }
    }

    /// Coerce this value to a `Date` or throw an error.
    public func date(_ columnName: String? = nil) throws -> Date {
        struct Formatters {
            static let iso8601DateFormatter: ISO8601DateFormatter = {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                return formatter
            }()

            static let simpleFormatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                return formatter
            }()
        }

        switch self {
        case .date(let value):
            return value
        case .int(let value):
            return Date(timeIntervalSince1970: Double(value))
        case .double(let value):
            return Date(timeIntervalSince1970: value)
        case .string(let value):
            guard
                let date = Formatters.iso8601DateFormatter.date(from: value)
                    ?? Formatters.simpleFormatter.date(from: value)
            else {
                throw typeError("Date", columnName: columnName)
            }

            return date
        case .null:
            throw nullError(columnName)
        default:
            throw typeError("Date", columnName: columnName)
        }
    }

    /// Coerce this value to JSON `Data` or throw an error.
    public func json(_ columnName: String? = nil) throws -> ByteBuffer {
        switch self {
        case .json(let bytes):
            return bytes
        case .string(let string):
            return ByteBuffer(string: string)
        case .null:
            throw nullError(columnName)
        default:
            throw typeError("JSON", columnName: columnName)
        }
    }

    /// Coerce this value to a `UUID` or throw an error.
    public func uuid(_ columnName: String? = nil) throws -> UUID {
        switch self {
        case .uuid(let value):
            return value
        case .string(let string):
            guard let uuid = UUID(string) else {
                throw typeError("UUID", columnName: columnName)
            }

            return uuid
        case .null:
            throw nullError(columnName)
        default:
            throw typeError("UUID", columnName: columnName)
        }
    }

    private func nullError(_ columnName: String? = nil) -> Error {
        let desc = columnName.map { "`\($0)`" } ?? "column"
        return DatabaseError("Expected value at \(desc) to have a value but it was `nil`.")
    }

    private func typeError(_ typeName: String, columnName: String? = nil) -> Error {
        let detail = columnName.map { "at column `\($0)` " } ?? ""
        return DatabaseError("Unable to coerce value `\(self)` \(detail)to \(typeName).")
    }
}
