import NIOConcurrencyHelpers

final class EventBus {
    enum Handler<E: Event>: AnyHandler {
        typealias Closure = (E) async throws -> Void
        case closure(Closure)
    }
    
    private var registeredHandlers: [String: [AnyHandler]] = [:]
    private var lock = Lock()
    
    func observe<E: Event>(_ event: E.Type, action: @escaping Handler<E>.Closure) {
        let _handlers = lock.withLock { registeredHandlers[E.registrationKey] ?? [] }
        guard let existingHandlers = _handlers as? [Handler<E>] else { return }
        registeredHandlers[E.registrationKey] = existingHandlers + [.closure(action)]
    }
    
    func observe<L: Listener>(listener: L.Type) {
        let _handlers = lock.withLock { registeredHandlers[L.ObservedEvent.registrationKey] ?? [] }
        guard let existingHandlers = _handlers as? [Handler<L.ObservedEvent>] else { return }
        registeredHandlers[L.ObservedEvent.registrationKey] = existingHandlers + [.closure {
            try await L(event: $0).handle()
        }]
    }
    
    func dispatch<E: Event>(event: E) async throws {
        let _handlers = lock.withLock { registeredHandlers[E.registrationKey] ?? [] }
        guard let handlers = _handlers as? [Handler<E>] else {
            return
        }
        
        for handler in handlers {
            switch handler {
            case .closure(let closure):
                try await closure(event)
            }
        }
    }
}

extension Listener {
    fileprivate func handle() async throws { try await run() }
}

extension Listener where Self: Job {
    fileprivate func handle() async throws { try await dispatch() }
}

private protocol AnyHandler {}
