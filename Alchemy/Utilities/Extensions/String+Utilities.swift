extension StringProtocol {
    var inQuotes: String {
        "\"\(self)\""
    }

    var inSingleQuotes: String {
        "'\(self)'"
    }
}

extension String {
    var trimmingQuotes: String {
        trimmingCharacters(in: CharacterSet(charactersIn: #""'"#))
    }
    
    var trimmingForwardSlash: String {
        trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    func droppingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count))
    }
    
    func droppingSuffix(_ suffix: String) -> String {
        guard hasSuffix(suffix) else { return self }
        return String(dropLast(suffix.count))
    }

    func replacingFirstOccurrence(of string: String, with replacement: String) -> String {
        if let range = range(of: string) {
            return replacingCharacters(in: range, with: replacement)
        } else {
            return self
        }
    }
}

extension Collection<String> {
    var commaJoined: String {
        joined(separator: ", ")
    }
}
