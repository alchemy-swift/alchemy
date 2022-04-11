public protocol HashAlgorithm {
    func verify(_ plaintext: String, hash: String) throws -> Bool
    func make(_ value: String) throws -> String
}
