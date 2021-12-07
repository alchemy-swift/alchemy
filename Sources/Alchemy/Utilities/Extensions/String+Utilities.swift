extension String {
    var trimmingQuotes: String {
        trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
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
}
