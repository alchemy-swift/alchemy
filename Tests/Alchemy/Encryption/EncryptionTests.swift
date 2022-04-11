@testable import Alchemy
import AlchemyTest
import Crypto

final class EncryptionTests: XCTestCase {
    func testEncrypter() throws {
        let initialKey = SymmetricKey(size: .bits256)
        let initialEncryptor = Encrypter(key: initialKey)
        let initialCipher = try initialEncryptor.encrypt(string: "FOO")
        
        let keyString = initialKey.withUnsafeBytes { Data($0) }.base64EncodedString()
        guard let keyData = Data(base64Encoded: keyString) else {
            return XCTFail("couldn't decode")
        }
        
        let recreatedKey = SymmetricKey(data: keyData)
        let encrypter = Encrypter(key: recreatedKey)
        let cipher = try encrypter.encrypt(string: "FOO")
        let decrypted = try encrypter.decrypt(data: cipher)
        let initialDecrypted = try encrypter.decrypt(data: initialCipher)
        XCTAssertEqual("FOO", decrypted)
        XCTAssertEqual("FOO", initialDecrypted)
    }
    
    func testDecryptStringNotBase64Throws() {
        let key = SymmetricKey(size: .bits256)
        let encrypter = Encrypter(key: key)
        XCTAssertThrowsError(try encrypter.decrypt(base64Encoded: "foo"))
    }

    func testEncrypted() throws {
        Env.stub(["APP_KEY": Encrypter.generateKeyString()])
        
        let value = "FOO"
        let encryptedValue = try Crypt.encrypt(string: value).base64EncodedString()
        let reader: FakeReader = ["foo": encryptedValue]
        let encrypted = try Encrypted(key: "foo", on: reader)
        XCTAssertEqual(encrypted.wrappedValue, "FOO")
        
        var writer: SQLRowWriter = FakeWriter()
        try encrypted.store(key: "foo", on: &writer)
        guard let storedValue = (writer as? FakeWriter)?.dict["foo"] else {
            return XCTFail("a value wasn't stored")
        }
        
        let decrypted = try Crypt.decrypt(base64Encoded: storedValue.string())
        XCTAssertEqual(decrypted, value)
    }
    
    func testEncryptedNotBase64Throws() {
        let reader: FakeReader = ["foo": "bar"]
        XCTAssertThrowsError(try Encrypted(key: "foo", on: reader))
    }
}

private struct FakeWriter: SQLRowWriter {
    var dict: [String: SQLValue] = [:]
    
    subscript(column: String) -> SQLValue? {
        get { dict[column] }
        set { dict[column] = newValue }
    }
    
    mutating func put<E: Encodable>(json: E, at key: String) throws {
        let jsonData = try JSONEncoder().encode(json)
        self[key] = .json(jsonData)
    }
}

private struct FakeReader: SQLRowReader, ExpressibleByDictionaryLiteral {
    var row: SQLRow
    
    init(dictionaryLiteral: (String, SQLValueConvertible)...) {
        self.row = SQLRow(fields: dictionaryLiteral.map { SQLField(column: $0, value: $1.sqlValue) })
    }
    
    func requireJSON<D: Decodable>(_ key: String) throws -> D {
        return try JSONDecoder().decode(D.self, from: row.require(key).json(key))
    }
    
    func require(_ key: String) throws -> SQLValue {
        try row.require(key)
    }
    
    func contains(_ column: String) -> Bool {
        row[column] != nil
    }
    
    subscript(_ index: Int) -> SQLValue {
        row[index]
    }
    
    subscript(_ column: String) -> SQLValue? {
        row[column]
    }
}
