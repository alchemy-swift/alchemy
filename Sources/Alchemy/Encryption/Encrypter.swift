import Crypto

enum EncryptionError: Error {
    case stringNotBase64Encoded
    case misc
}

extension SymmetricKey {
    public static let app = SymmetricKey(size: .bits256)
}

public struct Encrypter {
    
    public func encrypt(_ string: String, key: SymmetricKey = .app) throws -> Data {
        let message = Data(string.utf8)
        guard let result = try AES.GCM.seal(message, using: key).combined else {
            throw EncryptionError.misc
        }
        
        return result
    }
    
    public func decrypt(_ data: Data, key: SymmetricKey = .app) throws -> String {
        let box = try AES.GCM.SealedBox(combined: data)
        let data = try AES.GCM.open(box, using: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw EncryptionError.misc
        }
        
        return string
    }
}

@propertyWrapper
public struct Encrypted: ModelProperty {
    public var wrappedValue: String

    // MARK: ModelProperty

    public init(key: String, on row: SQLRowReader) throws {
        let encrypted = try row.require(key).string()
        guard let data = Data(base64Encoded: encrypted) else {
            throw EncryptionError.stringNotBase64Encoded
        }
        
        wrappedValue = try Crypt.decrypt(data)
    }

    public func store(key: String, on row: inout SQLRowWriter) throws {
        let encrypted = try Crypt.encrypt(wrappedValue)
        let string = encrypted.base64EncodedString()
        row.put(.string(string), at: key)
    }
}
