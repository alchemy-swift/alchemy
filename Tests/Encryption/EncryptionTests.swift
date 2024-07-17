import AlchemyTest
import Crypto

@testable import Alchemy

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
        Environment.stub(["APP_KEY": Encrypter.generateKeyString()])

        let string = "FOO"
        let encryptedValue = try Crypt.encrypt(string: string).base64EncodedString()
        let reader: SQLRowReader = ["foo": encryptedValue]
        let encrypted = try Encrypted(key: "foo", on: reader)
        XCTAssertEqual(encrypted.wrappedValue, "FOO")

        var writer = SQLRowWriter()
        try encrypted.store(key: "foo", on: &writer)
        guard let storedValue = writer.fields["foo"] as? String else {
            return XCTFail("a String wasn't stored")
        }

        let decrypted = try Crypt.decrypt(base64Encoded: storedValue)
        XCTAssertEqual(decrypted, string)
    }

    func testEncryptedNotBase64Throws() {
        let reader: SQLRowReader = ["foo": "bar"]
        XCTAssertThrowsError(try Encrypted(key: "foo", on: reader))
    }
}

extension SQLRowReader: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral: (String, SQLValueConvertible)...) {
        self.init(row: SQLRow(fields: dictionaryLiteral))
    }
}
