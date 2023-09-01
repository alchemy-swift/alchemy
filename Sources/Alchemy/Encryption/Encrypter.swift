import Crypto

extension SymmetricKey {
    public static var app: SymmetricKey = {
        guard let appKey: String = Env.APP_KEY else {
            preconditionFailure("Unable to load APP_KEY from Environment. Please set an APP_KEY before encrypting any data with `Crypt` or provide a custom `SymmetricKey` using `Crypt(key:)`.")
        }
        
        guard let data = Data(base64Encoded: appKey) else {
            preconditionFailure("Unable to create encryption key from APP_KEY. Please ensure APP_KEY is a base64 encoded String.")
        }
        
        return SymmetricKey(data: data)
    }()
}

public struct Encrypter {
    private let key: SymmetricKey
    
    public init(key: SymmetricKey) {
        self.key = key
    }
    
    public func encrypt(string: String) throws -> Data {
        try encrypt(data: Data(string.utf8))
    }
    
    public func encrypt<D: DataProtocol>(data: D) throws -> Data {
        guard let result = try AES.GCM.seal(data, using: key).combined else {
            throw EncryptionError("could not encrypt the data")
        }
        
        return result
    }
    
    public func decrypt(base64Encoded string: String) throws -> String {
        guard let data = Data(base64Encoded: string) else {
            throw EncryptionError("the string wasn't base64 encoded")
        }
        
        return try decrypt(data: data)
    }
    
    public func decrypt<D: DataProtocol>(data: D) throws -> String {
        let box = try AES.GCM.SealedBox(combined: data)
        let data = try AES.GCM.open(box, using: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw EncryptionError("could not decrypt the data")
        }
        
        return string
    }
    
    public static func generateKeyString(size: SymmetricKeySize = .bits256) -> String {
        SymmetricKey(size: size).withUnsafeBytes { Data($0) }.base64EncodedString()
    }
}
