public struct ModelDidFetch<M: Model>: Event {
    public let models: [M]
}

struct ModelWillCreate<M: Model>: Event {
    let models: [M]
}

struct ModelDidCreate<M: Model>: Event {
    let models: [M]
}

struct ModelWillUpdate<M: Model>: Event {
    let models: [M]
}

struct ModelDidUpdate<M: Model>: Event {
    let models: [M]
}

struct ModelWillDelete<M: Model>: Event {
    let models: [M]
}

struct ModelDidDelete<M: Model>: Event {
    let models: [M]
}

struct ModelWillSave<M: Model>: Event {
    let models: [M]
}

struct ModelDidSave<M: Model>: Event {
    let models: [M]
}

protocol EventDelegate {
    // Soft Delete
    func didHardDelete()
    func didSoftDelete()
    func willRestore()
    func didRestore()
}

extension EventBus {
    public func onDidFetch<M: Model>(_ type: M.Type, action: @escaping (ModelDidFetch<M>) async throws -> Void) {
        on(ModelDidFetch<M>.self, action: action)
    }
}
