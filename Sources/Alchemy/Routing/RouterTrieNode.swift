final class RouterTrieNode<StorageKey: Hashable, StorageObject> {
    var storage: [StorageKey: StorageObject] = [:]
    var children: [String: RouterTrieNode] = [:]
    var wildcardChildren: [String: RouterTrieNode] = [:]
    
    func search(path: [String], storageKey: StorageKey) -> (StorageObject, [PathParameter])? {
        if let first = path.first {
            let newPath = Array(path.dropFirst())
            if let matchingChild = self.children[first] {
                return matchingChild.search(path: newPath, storageKey: storageKey)
            } else {
                for (wildcard, node) in self.wildcardChildren {
                    guard var val = node.search(path: newPath, storageKey: storageKey) else {
                        continue
                    }
                    
                    val.1.append(PathParameter(parameter: wildcard, stringValue: first))
                    
                    return val
                }
                return nil
            }
        } else {
            return self.storage[storageKey].map { ($0, []) }
        }
    }
    
    func insert(path: [String], storageKey: StorageKey, value: StorageObject) {
        if let first = path.first {
            let child = Self()
            child.insert(path: Array(path.dropFirst()), storageKey: storageKey, value: value)
            if first.hasPrefix(":") {
                self.wildcardChildren[first] = child
            } else {
                self.children[first] = child
            }
        } else {
            self.storage[storageKey] = value
        }
    }
}
