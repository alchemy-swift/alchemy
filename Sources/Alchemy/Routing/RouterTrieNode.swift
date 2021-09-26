/// A trie that stores objects at each node. Supports wildcard path
/// elements denoted by a ":" at the beginning.
final class RouterTrieNode<StorageKey: Hashable, StorageObject> {
    /// Storage of the objects at this node.
    private var storage: [StorageKey: StorageObject] = [:]
    /// This node's children, mapped by their path for instant lookup.
    private var children: [String: RouterTrieNode] = [:]
    /// Any children with wildcards in their path.
    private var wildcardChildren: [String: RouterTrieNode] = [:]
    
    /// Search this node & it's children for an object at a path,
    /// stored with the given key.
    ///
    /// - Parameters:
    ///   - path: The path of the object to search for. If this is
    ///     empty, it is assumed the object can only be at this node.
    ///   - storageKey: The key by which the object is stored.
    /// - Returns: A tuple containing the object and any parsed path
    ///   parameters. `nil` if the object isn't in this node or its
    ///   children.
    func search(path: [String], storageKey: StorageKey) -> (value: StorageObject, parameters: [PathParameter])? {
        if let first = path.first {
            let newPath = Array(path.dropFirst())
            if let matchingChild = self.children[first] {
                return matchingChild.search(path: newPath, storageKey: storageKey)
            } else {
                for (wildcard, node) in self.wildcardChildren {
                    guard var val = node.search(path: newPath, storageKey: storageKey) else {
                        continue
                    }
                    
                    val.1.insert(PathParameter(parameter: wildcard, stringValue: first), at: 0)
                    return val
                }
                return nil
            }
        } else {
            return self.storage[storageKey].map { ($0, []) }
        }
    }
    
    /// Inserts a value at the given path with a storage key.
    ///
    /// - Parameters:
    ///   - path: The path to the node where this value should be
    ///     stored.
    ///   - storageKey: The key by which to store the value.
    ///   - value: The value to store.
    func insert(path: [String], storageKey: StorageKey, value: StorageObject) {
        if let first = path.first {
            if first.hasPrefix(":") {
                let firstWithoutEscape = String(first.dropFirst())
                let child = self.wildcardChildren[firstWithoutEscape] ?? Self()
                child.insert(path: Array(path.dropFirst()), storageKey: storageKey, value: value)
                self.wildcardChildren[firstWithoutEscape] = child
            } else {
                let child = self.children[first] ?? Self()
                child.insert(path: Array(path.dropFirst()), storageKey: storageKey, value: value)
                self.children[first] = child
            }
        } else {
            self.storage[storageKey] = value
        }
    }
}
