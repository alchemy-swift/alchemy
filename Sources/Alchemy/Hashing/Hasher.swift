public struct Hasher<Algorithm: HashAlgorithm> {
    let algorithm: Algorithm
    
    public init(algorithm: Algorithm) {
        self.algorithm = algorithm
    }
    
    public func make(_ value: String) throws -> String {
        try algorithm.make(value)
    }
    
    public func verify(_ plaintext: String, hash: String) throws -> Bool {
        try algorithm.verify(plaintext, hash: hash)
    }
    
    // MARK: Async Support

    public func makeAsync(_ value: String) async throws -> String {
        try await Thread.run { try make(value) }
    }
    
    public func verifyAsync(_ plaintext: String, hash: String) async throws -> Bool {
        try await Thread.run { try verify(plaintext, hash: hash) }
    }
}
