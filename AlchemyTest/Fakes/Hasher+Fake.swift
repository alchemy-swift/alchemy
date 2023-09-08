extension Hasher {
    /// Fakes the default hasher with a plaintext hasher.
    public static func fake() {
        Container.register(Hasher(algorithm: .plaintext)).singleton()
    }
}
