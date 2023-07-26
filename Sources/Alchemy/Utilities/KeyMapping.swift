import Foundation

/// Represents the mapping between your type's property names and
/// their corresponding request field key.
public enum KeyMapping {
    /// Use the literal name for all properties on a type as its field key.
    case useDefaultKeys

    /// Convert property names from camelCase to snake_case for field keys.
    ///
    /// e.g. `someGreatString` -> `some_great_string`
    case snakeCase

    /// A custom key mapping.
    case custom(to: (String) -> String, from: (String) -> String)

    /// Encode String from camelCase to this KeyMapping strategy.
    public func encode(_ string: String) -> String {
        switch self {
        case .snakeCase:
            return string.camelCaseToSnakeCase()
        case .useDefaultKeys:
            return string
        case .custom(let toMapper, _):
            return toMapper(string)
        }
    }

    /// Decode a String from this KeyMapping strategy to camelCase.
    public func decode(_ string: String) -> String {
        switch self {
        case .snakeCase:
            return string.camelCaseFromSnakeCase()
        case .useDefaultKeys:
            return string
        case .custom(_, let fromMapper):
            return fromMapper(string)
        }
    }
}

extension String {
    /// Map camelCase to snake_case. Assumes `self` is already in
    /// camelCase. Copied from `Foundation`.
    ///
    /// - Returns: The snake_cased version of `self`.
    fileprivate func camelCaseToSnakeCase() -> String {
        guard !self.isEmpty else { return self }

        var words : [Range<String.Index>] = []
        // The general idea of this algorithm is to split words on transition from lower to upper case, then on transition of >1 upper case characters to lowercase
        //
        // myProperty -> my_property
        // myURLProperty -> my_url_property
        //
        // We assume, per Swift naming conventions, that the first character of the key is lowercase.
        var wordStart = self.startIndex
        var searchRange = self.index(after: wordStart)..<self.endIndex

        // Find next uppercase character
        while let upperCaseRange = self.rangeOfCharacter(from: CharacterSet.uppercaseLetters, options: [], range: searchRange) {
            let untilUpperCase = wordStart..<upperCaseRange.lowerBound
            words.append(untilUpperCase)

            // Find next lowercase character
            searchRange = upperCaseRange.lowerBound..<searchRange.upperBound
            guard let lowerCaseRange = self.rangeOfCharacter(from: CharacterSet.lowercaseLetters, options: [], range: searchRange) else {
                // There are no more lower case letters. Just end here.
                wordStart = searchRange.lowerBound
                break
            }

            // Is the next lowercase letter more than 1 after the uppercase? If so, we encountered a group of uppercase letters that we should treat as its own word
            let nextCharacterAfterCapital = self.index(after: upperCaseRange.lowerBound)
            if lowerCaseRange.lowerBound == nextCharacterAfterCapital {
                // The next character after capital is a lower case character and therefore not a word boundary.
                // Continue searching for the next upper case for the boundary.
                wordStart = upperCaseRange.lowerBound
            } else {
                // There was a range of >1 capital letters. Turn those into a word, stopping at the capital before the lower case character.
                let beforeLowerIndex = self.index(before: lowerCaseRange.lowerBound)
                words.append(upperCaseRange.lowerBound..<beforeLowerIndex)

                // Next word starts at the capital before the lowercase we just found
                wordStart = beforeLowerIndex
            }
            searchRange = lowerCaseRange.upperBound..<searchRange.upperBound
        }

        words.append(wordStart..<searchRange.upperBound)
        return words
            .map { range in
                self[range].lowercased()
            }
            .joined(separator: "_")
    }

    fileprivate func camelCaseFromSnakeCase() -> String {
        let stringKey = self
        guard !stringKey.isEmpty else { return stringKey }

        // Find the first non-underscore character
        guard let firstNonUnderscore = stringKey.firstIndex(where: { $0 != "_" }) else {
            // Reached the end without finding an _
            return stringKey
        }

        // Find the last non-underscore character
        var lastNonUnderscore = stringKey.index(before: stringKey.endIndex)
        while lastNonUnderscore > firstNonUnderscore && stringKey[lastNonUnderscore] == "_" {
            stringKey.formIndex(before: &lastNonUnderscore)
        }

        let keyRange = firstNonUnderscore...lastNonUnderscore
        let leadingUnderscoreRange = stringKey.startIndex..<firstNonUnderscore
        let trailingUnderscoreRange = stringKey.index(after: lastNonUnderscore)..<stringKey.endIndex

        let components = stringKey[keyRange].split(separator: "_")
        let joinedString: String
        if components.count == 1 {
            // No underscores in key, leave the word as is - maybe already camel cased
            joinedString = String(stringKey[keyRange])
        } else {
            joinedString = ([components[0].lowercased()] + components[1...].map { $0.capitalized }).joined()
        }

        // Do a cheap isEmpty check before creating and appending potentially empty strings
        let result: String
        if (leadingUnderscoreRange.isEmpty && trailingUnderscoreRange.isEmpty) {
            result = joinedString
        } else if (!leadingUnderscoreRange.isEmpty && !trailingUnderscoreRange.isEmpty) {
            // Both leading and trailing underscores
            result = String(stringKey[leadingUnderscoreRange]) + joinedString + String(stringKey[trailingUnderscoreRange])
        } else if (!leadingUnderscoreRange.isEmpty) {
            // Just leading
            result = String(stringKey[leadingUnderscoreRange]) + joinedString
        } else {
            // Just trailing
            result = joinedString + String(stringKey[trailingUnderscoreRange])
        }

        return result
    }
}
