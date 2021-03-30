import Foundation

extension Encodable {
    public func jsonString(using encoder: JSONEncoder = JSONEncoder()) throws -> String {
        try String(data: encoder.encode(self), encoding: .utf8)
            .unwrap(or: AlchemyError("Unable to encode `\(Self.self)` to a JSON string."))
    }
}

extension Decodable {
    public init(jsonString: String, using decoder: JSONDecoder = JSONDecoder()) throws {
        let data = try jsonString.data(using: .utf8)
            .unwrap(or: AlchemyError("Unable to initialize `\(Self.self)` from JSON string `\(jsonString)`."))
        self = try decoder.decode(Self.self, from: data)
    }
}
