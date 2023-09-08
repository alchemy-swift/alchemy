extension Environment {
    /// Fakes the environment with the given name and values.
    public static func fake(name: String = "fake", values: [String: String]) {
        Container.register(Environment(name: name, dotenvVariables: values)).singleton()
    }
}
