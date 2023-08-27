/// Adds convenient extensions for accessing Model events.
extension EventBus {
    public func onDidFetch<M: Model>(_ type: M.Type, action: @escaping (ModelDidFetch<M>) async throws -> Void) {
        on(ModelDidFetch<M>.self, handler: action)
    }
    
    public func onWillCreate<M: Model>(_ type: M.Type, action: @escaping (ModelWillCreate<M>) async throws -> Void) {
        on(ModelWillCreate<M>.self, handler: action)
    }
    
    public func onDidCreate<M: Model>(_ type: M.Type, action: @escaping (ModelDidCreate<M>) async throws -> Void) {
        on(ModelDidCreate<M>.self, handler: action)
    }

    public func onWillUpsert<M: Model>(_ type: M.Type, action: @escaping (ModelWillUpsert<M>) async throws -> Void) {
        on(ModelWillUpsert<M>.self, handler: action)
    }

    public func onDidUpsert<M: Model>(_ type: M.Type, action: @escaping (ModelDidUpsert<M>) async throws -> Void) {
        on(ModelDidUpsert<M>.self, handler: action)
    }

    public func onWillUpdate<M: Model>(_ type: M.Type, action: @escaping (ModelWillUpdate<M>) async throws -> Void) {
        on(ModelWillUpdate<M>.self, handler: action)
    }
    
    public func onDidUpdate<M: Model>(_ type: M.Type, action: @escaping (ModelDidUpdate<M>) async throws -> Void) {
        on(ModelDidUpdate<M>.self, handler: action)
    }
    
    public func onWillSave<M: Model>(_ type: M.Type, action: @escaping (ModelWillSave<M>) async throws -> Void) {
        on(ModelWillSave<M>.self, handler: action)
    }
    
    public func onDidSave<M: Model>(_ type: M.Type, action: @escaping (ModelDidSave<M>) async throws -> Void) {
        on(ModelDidSave<M>.self, handler: action)
    }
    
    public func onWillDelete<M: Model>(_ type: M.Type, action: @escaping (ModelWillDelete<M>) async throws -> Void) {
        on(ModelWillDelete<M>.self, handler: action)
    }
    
    public func onDidDelete<M: Model>(_ type: M.Type, action: @escaping (ModelDidDelete<M>) async throws -> Void) {
        on(ModelDidDelete<M>.self, handler: action)
    }
}

public struct ModelDidFetch<M: Model>: Event {
    public let models: [M]
}

public struct ModelWillCreate<M: Model>: Event {
    public let models: [M]
}

public struct ModelDidCreate<M: Model>: Event {
    public let models: [M]
}

public struct ModelWillUpsert<M: Model>: Event {
    public let models: [M]
}

public struct ModelDidUpsert<M: Model>: Event {
    public let models: [M]
}

public struct ModelWillUpdate<M: Model>: Event {
    public let models: [M]
}

public struct ModelDidUpdate<M: Model>: Event {
    public let models: [M]
}

public struct ModelWillDelete<M: Model>: Event {
    public let models: [M]
}

public struct ModelDidDelete<M: Model>: Event {
    public let models: [M]
}

public struct ModelWillSave<M: Model>: Event {
    public let models: [M]
}

public struct ModelDidSave<M: Model>: Event {
    public let models: [M]
}
