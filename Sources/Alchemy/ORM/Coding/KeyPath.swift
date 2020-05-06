import EchoProperties

extension PartialKeyPath {
    /// Get's the string name of a key path, or throws a `DatabaseEncodingError` if not found.
    func name() throws -> String {
        let all = Reflection.allNamedStoredPropertyKeyPaths(for: Root.self)
        for (name, kp) in all {
            // Doesn't seem to consistently work without the hash value.
            if kp.hashValue == self.hashValue {
                return name
            } else {
                // It doesn't work without this line. No clue why. Clearly some compiler juju going on with
                // this lib.
                var newName = name
                newName += ""
            }
        }
        
        throw DatabaseEncodingError(message: "Unable to find a name for KeyPath '\(self)'")
    }
}
