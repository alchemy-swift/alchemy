import Foundation

/// Represents the mapping between your type's property names and their
/// corresponding database column.
///
/// For example, you might be using a `PostgreSQL` database which has a
/// snake_case naming convention. Your `users` table might have fields `id`,
/// `email`, `first_name`, and `last_name`.
///
/// Since Swift's naming convention is camelCase, your corresponding database
/// model will probably look like this:
/// ```
/// struct User: Model {
///     var id: Int?
///     let email: String
///     let firstName: String // doesn't match database field of `first_name`
///     let lastName: String // doesn't match database field of `last_name`
/// }
/// ```
/// By overriding the `keyMappingStrategy` on `User`, you can customize the
/// mapping between the property names and database columns. Note that in the
/// example above you won't need to override, since keyMappingStrategy is, by
/// default, convertToSnakeCase.
public enum DatabaseKeyMappingStrategy {
    /// Use the literal name for all properties on an object as its
    /// corresponding database column.
    case useDefaultKeys
    
    /// Convert property names from camelCase to snake_case for the database
    /// columns.
    ///
    /// e.g. `someGreatString` -> `some_great_string`
    case convertToSnakeCase
    
    /// A custom mapping of property name to database column name.
    case custom((String) -> String)
    
    /// Given the strategy, map from an input string to an output string.
    ///
    /// - Parameter input: the input string, representing the name of the swift
    ///                    type's property
    /// - Returns: the output string, representing the column of the database's
    ///            table.
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
    /// Map camelCase to snake_case. Assumes `self` is already in camelCase.
    ///
    /// - Returns: the snake_cased version of `self`.
    fileprivate func camelCaseToSnakeCase() -> String {
        let acronymPattern = "([A-Z]+)([A-Z][a-z]|[0-9])"
        let normalPattern = "([a-z0-9])([A-Z])"
        return self.processCamalCaseRegex(pattern: acronymPattern)?
            .processCamalCaseRegex(pattern: normalPattern)?
            .lowercased() ?? self.lowercased()
    }
    
    /// Generates a string by replacing matches of a pattern with `$1_$2` in
    /// self.
    ///
    /// - Parameter pattern: the pattern to replace.
    /// - Returns: the replaced string.
    private func processCamalCaseRegex(pattern: String) -> String? {
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: count)
        return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2")
    }
}
