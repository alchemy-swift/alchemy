/// A one way hasher.
public protocol HashAlgorithm {
    /// Create a hash from the given value.
    func make(_ value: String) -> String
    
    /// Verifies a hashed value against a given un-hashed String.
    func verify(_ plaintext: String, hash: String) -> Bool
}
