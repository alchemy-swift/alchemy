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

extension EventBus {
    public func onDidFetch<M: Model>(_ type: M.Type, action: @escaping (ModelDidFetch<M>) async throws -> Void) {
        listen(ModelDidFetch<M>.self, handler: action)
    }
    
    public func onWillCreate<M: Model>(_ type: M.Type, action: @escaping (ModelWillCreate<M>) async throws -> Void) {
        listen(ModelWillCreate<M>.self, handler: action)
    }
    
    public func onDidCreate<M: Model>(_ type: M.Type, action: @escaping (ModelDidCreate<M>) async throws -> Void) {
        listen(ModelDidCreate<M>.self, handler: action)
    }

    public func onWillUpsert<M: Model>(_ type: M.Type, action: @escaping (ModelWillUpsert<M>) async throws -> Void) {
        listen(ModelWillUpsert<M>.self, handler: action)
    }

    public func onDidUpsert<M: Model>(_ type: M.Type, action: @escaping (ModelDidUpsert<M>) async throws -> Void) {
        listen(ModelDidUpsert<M>.self, handler: action)
    }

    public func onWillUpdate<M: Model>(_ type: M.Type, action: @escaping (ModelWillUpdate<M>) async throws -> Void) {
        listen(ModelWillUpdate<M>.self, handler: action)
    }
    
    public func onDidUpdate<M: Model>(_ type: M.Type, action: @escaping (ModelDidUpdate<M>) async throws -> Void) {
        listen(ModelDidUpdate<M>.self, handler: action)
    }
    
    public func onWillSave<M: Model>(_ type: M.Type, action: @escaping (ModelWillSave<M>) async throws -> Void) {
        listen(ModelWillSave<M>.self, handler: action)
    }
    
    public func onDidSave<M: Model>(_ type: M.Type, action: @escaping (ModelDidSave<M>) async throws -> Void) {
        listen(ModelDidSave<M>.self, handler: action)
    }
    
    public func onWillDelete<M: Model>(_ type: M.Type, action: @escaping (ModelWillDelete<M>) async throws -> Void) {
        listen(ModelWillDelete<M>.self, handler: action)
    }
    
    public func onDidDelete<M: Model>(_ type: M.Type, action: @escaping (ModelDidDelete<M>) async throws -> Void) {
        listen(ModelDidDelete<M>.self, handler: action)
    }
}
