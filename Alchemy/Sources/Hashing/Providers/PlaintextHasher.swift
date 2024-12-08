extension HashAlgorithm where Self == BCryptHasher {
    public static var plaintext: PlaintextHasher {
        PlaintextHasher()
    }
}

/// A hash algorithm for testing that just returns the value as plaintext.
public struct PlaintextHasher: HashAlgorithm {
    public func make(_ value: String) -> String {
        value
    }

    public func verify(_ plaintext: String, hash: String) -> Bool {
        plaintext == hash
    }
}
