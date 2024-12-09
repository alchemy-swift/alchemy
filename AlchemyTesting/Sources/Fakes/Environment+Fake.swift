extension Environment {
    /// Fakes the environment with the given name and values.
    public func fake(_ values: [String: String]) {
        self.name = "fake"
        self.dotenvPaths = []
        self.dotenvVariables = [:]
        self.processVariables = [:]
        self.runtimeOverrides = values
    }
}
