@propertyWrapper
public struct Encrypted: ModelProperty, Codable {
    public var wrappedValue: String

    // MARK: ModelProperty

    public init(key: String, on row: SQLRowReader) throws {
        let encrypted = try row.require(key).string(key)
        guard let data = Data(base64Encoded: encrypted) else {
            throw EncryptionError("could not decrypt data; it wasn't base64 encoded")
        }
        
        wrappedValue = try Crypt.decrypt(data: data)
    }

    public func store(key: String, on row: inout SQLRowWriter) throws {
        let encrypted = try Crypt.encrypt(string: wrappedValue)
        let string = encrypted.base64EncodedString()
        row.put(string, at: key)
    }
}
