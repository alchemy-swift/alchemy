import Foundation

extension String {
    func replaceAll(matching pattern: String, callback: (Int, String) -> String?) -> String {
        let expression = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = expression.matches(in: self, options: [], range: NSRange(startIndex..<endIndex, in: self))
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
