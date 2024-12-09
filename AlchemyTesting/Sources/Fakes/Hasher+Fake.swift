extension Hasher {
    /// Fakes the default hasher with a plaintext hasher.
    public func fake() {
        algorithm = .plaintext
    }
}
