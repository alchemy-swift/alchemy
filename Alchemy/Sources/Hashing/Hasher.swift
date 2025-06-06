public final class Hasher {
    package var algorithm: HashAlgorithm

    public init(algorithm: HashAlgorithm) {
        self.algorithm = algorithm
    }
    
    public func makeSync(_ value: String) -> String {
        algorithm.make(value)
    }
    
    public func verifySync(_ plaintext: String, hash: String) -> Bool {
        algorithm.verify(plaintext, hash: hash)
    }
    
    // MARK: Async Support

    public func make(_ value: String) async throws -> String {
        try await Thread.run { self.makeSync(value) }
    }
    
    public func verify(_ plaintext: String, hash: String) async throws -> Bool {
        try await Thread.run { self.verifySync(plaintext, hash: hash) }
    }
}
