import Foundation

/// A type that can be encoded to & from a `Database`. Likely represents a table in a relational database.
public protocol DatabaseCodable: Codable, DatabaseIdentifiable, Table {
    /// How should the swift `CodingKey`s be mapped to database columns? Defaults to `useDefaultKeys`.
    static var keyMappingStrategy: DatabaseKeyMappingStrategy { get }
}

public protocol DatabaseIdentifiable: Identifiable {
    associatedtype Identifier: Codable
    var id: Self.Identifier { get }
}

public enum DatabaseKeyMappingStrategy {
    case useDefaultKeys
    case convertToSnakeCase
    case custom((String) -> String)
    
    func map(input: String) -> String {
        switch self {
        case .convertToSnakeCase:
            return input.camelCaseToSnakeCase()
        case .useDefaultKeys:
            return input
        case .custom(let mapper):
            return mapper(input)
        }
    }
}

extension String {
    fileprivate func camelCaseToSnakeCase() -> String {
        let acronymPattern = "([A-Z]+)([A-Z][a-z]|[0-9])"
        let normalPattern = "([a-z0-9])([A-Z])"
        return self.processCamalCaseRegex(pattern: acronymPattern)?
            .processCamalCaseRegex(pattern: normalPattern)?.lowercased() ?? self.lowercased()
    }
    
    private func processCamalCaseRegex(pattern: String) -> String? {
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: count)
        return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2")
    }
}

extension DatabaseCodable {
    public static var keyMappingStrategy: DatabaseKeyMappingStrategy { .useDefaultKeys }
}
