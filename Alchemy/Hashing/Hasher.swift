public struct Hasher: IdentifiedService {
    public typealias Identifier = ServiceIdentifier<Database>

    private let algorithm: HashAlgorithm

    public init(algorithm: HashAlgorithm) {
        self.algorithm = algorithm
    }
    
    public func makeSync(_ value: String) throws -> String {
        try algorithm.make(value)
    }
    
    public func verifySync(_ plaintext: String, hash: String) throws -> Bool {
        try algorithm.verify(plaintext, hash: hash)
    }
    
    // MARK: Async Support

    public func make(_ value: String) async throws -> String {
        try await Thread.run { try makeSync(value) }
    }
    
    public func verify(_ plaintext: String, hash: String) async throws -> Bool {
        try await Thread.run { try verifySync(plaintext, hash: hash) }
    }
}
