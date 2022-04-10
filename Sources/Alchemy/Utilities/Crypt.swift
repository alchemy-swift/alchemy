import Crypto

public var Crypt: Encrypter {
    Encrypter()
}


public struct Encrypter {
    public func encrypt(_ string: String) throws -> String {
        string
    }
    
    public func decrypt(_ string: String) throws -> String {
        string
    }
}

@propertyWrapper
public struct Encrypted: ModelProperty {
    public var wrappedValue: String
    
    // MARK: ModelProperty
    
    public init(key: String, on row: SQLRowReader) throws {
        let encrypted = try row.require(key).string()
        wrappedValue = try Crypt.decrypt(encrypted)
    }
    
    public func store(key: String, on row: inout SQLRowWriter) throws {
        let encrypted = try Crypt.encrypt(wrappedValue)
        row.put(.string(encrypted), at: key)
    }
}
