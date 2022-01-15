/// A trie that stores objects at each node. Supports wildcard path
/// elements denoted by a ":" at the beginning.
final class Trie<Value> {
    /// Storage of the object at this node.
    private var value: Value?
    /// This node's children, mapped by their path for instant lookup.
    private var children: [String: Trie] = [:]
    /// Any children with parameters in their path.
    private var parameterChildren: [String: Trie] = [:]
    
    /// Search this node & it's children for an object at a path.
    ///
    /// - Parameter path: The path of the object to search for. If this is
    ///   empty, it is assumed the object can only be at this node.
    /// - Returns: A tuple containing the object and any parsed path
    ///   parameters. `nil` if the object isn't in this node or its
    ///   children.
    func search(path: [String]) -> (value: Value, parameters: [Parameter])? {
        if let first = path.first {
            let newPath = Array(path.dropFirst())
            if let matchingChild = children[first] {
                return matchingChild.search(path: newPath)
            }
            
            for (wildcard, node) in parameterChildren {
                guard var val = node.search(path: newPath) else {
                    continue
                }
                
                val.parameters.insert(Parameter(key: wildcard, value: first), at: 0)
                return val
            }
            
            return nil
        }
        
        return value.map { ($0, []) }
    }
    
    /// Inserts a value at the given path.
    ///
    /// - Parameters:
    ///   - path: The path to the node where this value should be
    ///     stored.
    ///   - value: The value to store.
    func insert(path: [String], value: Value) {
        if let first = path.first {
            if first.hasPrefix(":") {
                let firstWithoutEscape = String(first.dropFirst())
                let child = parameterChildren[firstWithoutEscape] ?? Self()
                child.insert(path: Array(path.dropFirst()), value: value)
                parameterChildren[firstWithoutEscape] = child
            } else {
                let child = children[first] ?? Self()
                child.insert(path: Array(path.dropFirst()), value: value)
                children[first] = child
            }
        } else {
            self.value = value
        }
    }
}
