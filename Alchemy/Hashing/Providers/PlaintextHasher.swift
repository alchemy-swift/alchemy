extension HashAlgorithm where Self == BCryptHasher {
    public static var plaintext: PlaintextHasher {
        PlaintextHasher()
    }
}

/// A hash algorithm for testing that just returns the value as plaintext.
public struct PlaintextHasher: HashAlgorithm {
    public init() {
        //
    }

    public func make(_ value: String) throws -> String {
        value
    }

    public func verify(_ plaintext: String, hash: String) throws -> Bool {
        plaintext == hash
    }
}
