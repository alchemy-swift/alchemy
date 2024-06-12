extension String {
    // Need this since `capitalized` lowercases everything else.
    var capitalizeFirst: String {
        prefix(1).capitalized + dropFirst()
    }
}

extension Collection {
    var nilIfEmpty: Self? {
        isEmpty ? self : nil
    }
}
