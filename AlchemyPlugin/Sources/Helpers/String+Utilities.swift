extension String {
    // Need this since `capitalized` lowercases everything else.
    var capitalizeFirst: String {
        prefix(1).capitalized + dropFirst()
    }

    var lowercaseFirst: String {
        prefix(1).lowercased() + dropFirst()
    }

    var withoutQuotes: String {
        filter { $0 != "\"" }
    }

    var inQuotes: String {
        "\"\(self)\""
    }

    var inParentheses: String {
        "(\(self))"
    }
}

extension Collection {
    var nilIfEmpty: Self? {
        isEmpty ? self : nil
    }
}
