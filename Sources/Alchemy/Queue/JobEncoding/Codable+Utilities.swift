import Foundation

extension Encodable {
    /// Encode this type into a JSON string.
    ///
    /// - Parameter encoder: The encoder to encode with. Defaults to
    ///   `JSONEncoder()`.
    /// - Throws: Any error encountered when encoding.
    /// - Returns: A JSON string representing this object.
    func jsonString(using encoder: JSONEncoder = JSONEncoder()) throws -> String {
        guard let string = try String(data: encoder.encode(self), encoding: .utf8) else {
            throw JobError("Unable to encode `\(Self.self)` to a JSON string.")
        }

        return string
    }
}

extension Decodable {
    /// Initialize this type from a JSON string.
    ///
    /// - Parameters:
    ///   - jsonString: The JSON string to initialize from.
    ///   - decoder: The decoder to decode with. Defaults to
    ///     `JSONDecoder()`.
    /// - Throws: Any error encountered when decoding this type.
    init(jsonString: String, using decoder: JSONDecoder = JSONDecoder()) throws {
        guard let data = jsonString.data(using: .utf8) else {
            throw JobError("Unable to initialize `\(Self.self)` from JSON string `\(jsonString)`.")
        }

        self = try decoder.decode(Self.self, from: data)
    }
}
