import Echo
import EchoMirror
import EchoProperties

// Getting some weird behavior with the `KeyPaths` where saving to the cache is causing them to have
// inconsistent hash values.
//
// Not using a cache for now.
extension KeyPath {
    /// Get's the string name of a key path, or nil if not found.
    public func storedName() -> String? {
        let all = Reflection.allNamedStoredPropertyKeyPaths(for: Root.self)
        for (name, kp) in all {
            if kp == self {
                return name
            }
        }
        
        return nil
    }
}
