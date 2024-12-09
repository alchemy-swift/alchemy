@testable
import Alchemy
import Crypto
import Foundation
import Testing

struct EncryptionTests {
    @Test func encrypter() throws {
        let initialKey = SymmetricKey(size: .bits256)
        let initialEncryptor = Encrypter(key: initialKey)
        let initialCipher = try initialEncryptor.encrypt(string: "FOO")

        let keyString = initialKey.withUnsafeBytes { Data($0) }.base64EncodedString()
        guard let keyData = Data(base64Encoded: keyString) else {
            Issue.record("couldn't decode")
            return
        }

        let recreatedKey = SymmetricKey(data: keyData)
        let encrypter = Encrypter(key: recreatedKey)
        let cipher = try encrypter.encrypt(string: "FOO")
        let decrypted = try encrypter.decrypt(data: cipher)
        let initialDecrypted = try encrypter.decrypt(data: initialCipher)
        #expect("FOO" == decrypted)
        #expect("FOO" == initialDecrypted)
    }

    @Test func decryptStringNotBase64Throws() {
        let key = SymmetricKey(size: .bits256)
        let encrypter = Encrypter(key: key)
        #expect(throws: Error.self) { try encrypter.decrypt(base64Encoded: "foo") }
    }

    @Test func encrypted() throws {
        Env.fake(["APP_KEY": Encrypter.generateKeyString()])

        let string = "FOO"
        let encryptedValue = try Crypt.encrypt(string: string).base64EncodedString()
        let reader: SQLRowReader = ["foo": encryptedValue]
        let encrypted = try Encrypted(key: "foo", on: reader)
        #expect(encrypted.wrappedValue == "FOO")

        var writer = SQLRowWriter()
        try encrypted.store(key: "foo", on: &writer)
        guard let storedValue = writer.fields["foo"] as? String else {
            Issue.record("a String wasn't stored")
            return
        }

        let decrypted = try Crypt.decrypt(base64Encoded: storedValue)
        #expect(decrypted == string)
    }

    @Test func encryptedNotBase64Throws() {
        let reader: SQLRowReader = ["foo": "bar"]
        #expect(throws: Error.self) { try Encrypted(key: "foo", on: reader) }
    }
}

extension SQLRowReader: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral: (String, SQLValueConvertible)...) {
        self.init(row: SQLRow(fields: dictionaryLiteral))
    }
}
