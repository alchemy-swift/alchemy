import Foundation

public protocol DatabaseJSON: Codable {
    /// Automatically provided using a default `JSONEncoder`. Override in your conforming type if you would
    /// like to customize the JSON serialization.
    func toJSONData() throws -> Data
}

extension DatabaseJSON {
    public func toJSONData() throws -> Data {
        try JSONEncoder().encode(self)
    }
}
