import Foundation

extension String {
    /// Replace all instances of a regex pattern with a string,
    /// determined by a closure.
    ///
    /// - Parameters:
    ///   - pattern: The pattern to replace.
    ///   - callback: The closure used to define replacements for the
    ///     pattern. Takes an index and a string that is the token to
    ///     replace.
    /// - Returns: The string with replaced patterns.
    func replaceAll(matching pattern: String, callback: (Int, String) -> String?) -> String {
        let expression = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = expression
            .matches(in: self, options: [], range: NSRange(startIndex..<endIndex, in: self))
        let size = matches.count - 1
        return matches.reversed()
            .enumerated()
            .reduce(into: self) { (current, match) in
                let (index, result) = match
                let range = Range(result.range, in: current)!
                let token = String(current[range])
                guard let replacement = callback(size-index, token) else { return }
                current.replaceSubrange(range, with: replacement)
        }
    }
}
