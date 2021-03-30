import Foundation

/// Represents the mapping between your type's property names and
/// their corresponding database column.
///
/// For example, you might be using a `PostgreSQL` database which has
/// a snake_case naming convention. Your `users` table might have
/// fields `id`, `email`, `first_name`, and `last_name`.
///
/// Since Swift's naming convention is camelCase, your corresponding
/// database model will probably look like this:
/// ```swift
/// struct User: Model {
///     var id: Int?
///     let email: String
///     let firstName: String // doesn't match database field of `first_name`
///     let lastName: String // doesn't match database field of `last_name`
/// }
/// ```
/// By overriding the `keyMappingStrategy` on `User`, you can
/// customize the mapping between the property names and
/// database columns. Note that in the example above you
/// won't need to override, since keyMappingStrategy is,
/// by default, convertToSnakeCase.
public enum DatabaseKeyMappingStrategy {
    /// Use the literal name for all properties on an object as its
    /// corresponding database column.
    case useDefaultKeys
    
    /// Convert property names from camelCase to snake_case for the
    /// database columns.
    ///
    /// e.g. `someGreatString` -> `some_great_string`
    case convertToSnakeCase
    
    /// A custom mapping of property name to database column name.
    case custom((String) -> String)
    
    /// Given the strategy, map from an input string to an output
    /// string.
    ///
    /// - Parameter input: The input string, representing the name of
    ///   the swift type's property
    /// - Returns: The output string, representing the column of the
    ///   database's table.
    public func map(input: String) -> String {
        switch self {
        case .convertToSnakeCase:
            return input.convertToSnakeCase()
        case .useDefaultKeys:
            return input
        case .custom(let mapper):
            return mapper(input)
        }
    }
}

extension String {
    private static var snakeCaseCache: [String: String] = [:]
    
    /// Map camelCase to snake_case. Assumes `self` is already in
    /// camelCase.
    ///
    /// - Returns: The snake_cased version of `self`.
    fileprivate func convertToSnakeCase() -> String {
        let stringKey = self
        guard !stringKey.isEmpty else { return stringKey }
    
        var words : [Range<String.Index>] = []
        // The general idea of this algorithm is to split words on transition from lower to upper case, then on transition of >1 upper case characters to lowercase
        //
        // myProperty -> my_property
        // myURLProperty -> my_url_property
        //
        // We assume, per Swift naming conventions, that the first character of the key is lowercase.
        var wordStart = stringKey.startIndex
        var searchRange = stringKey.index(after: wordStart)..<stringKey.endIndex
    
        // Find next uppercase character
        while let upperCaseRange = stringKey.rangeOfCharacter(from: CharacterSet.uppercaseLetters, options: [], range: searchRange) {
            let untilUpperCase = wordStart..<upperCaseRange.lowerBound
            words.append(untilUpperCase)
            
            // Find next lowercase character
            searchRange = upperCaseRange.lowerBound..<searchRange.upperBound
            guard let lowerCaseRange = stringKey.rangeOfCharacter(from: CharacterSet.lowercaseLetters, options: [], range: searchRange) else {
                // There are no more lower case letters. Just end here.
                wordStart = searchRange.lowerBound
                break
            }
            
            // Is the next lowercase letter more than 1 after the uppercase? If so, we encountered a group of uppercase letters that we should treat as its own word
            let nextCharacterAfterCapital = stringKey.index(after: upperCaseRange.lowerBound)
            if lowerCaseRange.lowerBound == nextCharacterAfterCapital {
                // The next character after capital is a lower case character and therefore not a word boundary.
                // Continue searching for the next upper case for the boundary.
                wordStart = upperCaseRange.lowerBound
            } else {
                // There was a range of >1 capital letters. Turn those into a word, stopping at the capital before the lower case character.
                let beforeLowerIndex = stringKey.index(before: lowerCaseRange.lowerBound)
                words.append(upperCaseRange.lowerBound..<beforeLowerIndex)
                
                // Next word starts at the capital before the lowercase we just found
                wordStart = beforeLowerIndex
            }
            searchRange = lowerCaseRange.upperBound..<searchRange.upperBound
        }
        words.append(wordStart..<searchRange.upperBound)
        let result = words.map({ (range) in
            return stringKey[range].lowercased()
        }).joined(separator: "_")
        return result
    }
}
