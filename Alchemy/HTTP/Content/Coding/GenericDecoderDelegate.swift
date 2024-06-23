protocol GenericDecoderDelegate {
    var allKeys: [String] { get }

    // MARK: Primitives

    func decodeString(for key: CodingKey?) throws -> String
    func decodeDouble(for key: CodingKey?) throws -> Double
    func decodeInt(for key: CodingKey?) throws -> Int
    func decodeBool(for key: CodingKey?) throws -> Bool
    func decodeNil(for key: CodingKey?) -> Bool
    
    // MARK: Map / Array

    func contains(key: CodingKey) -> Bool
    func dictionary(for key: CodingKey) throws -> GenericDecoderDelegate
    func array(for key: CodingKey?) throws -> [GenericDecoderDelegate]
}
