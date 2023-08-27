import NIOConcurrencyHelpers

public final class EventBus: Service {
    public struct Identifier: ServiceIdentifier {
        private let hashable: AnyHashable
        public init(hashable: AnyHashable) { self.hashable = hashable }
    }
    
    public enum Handler<E: Event>: AnyHandler {
        public typealias Closure = (E) async throws -> Void
        case closure(Closure)
    }
    
    private var registeredHandlers: [String: [AnyHandler]] = [:]
    private var lock = NIOLock()
    
    public func on<E: Event>(_ event: E.Type, action: @escaping Handler<E>.Closure) {
        let _handlers = lock.withLock { registeredHandlers[E.registrationKey] ?? [] }
        guard let existingHandlers = _handlers as? [Handler<E>] else { return }
        registeredHandlers[E.registrationKey] = existingHandlers + [.closure(action)]
    }
    
    public func register<L: Listener>(listener: L) {
        let _handlers = lock.withLock { registeredHandlers[L.ObservedEvent.registrationKey] ?? [] }
        guard let existingHandlers = _handlers as? [Handler<L.ObservedEvent>] else { return }
        registeredHandlers[L.ObservedEvent.registrationKey] = existingHandlers + [.closure {
            try await listener._handle(event: $0)
        }]
    }

    public func fire<E: Event>(_ event: E) async throws {
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

extension Event {
    /// Fire this event on an `EventBus`.
    public func fire(on events: EventBus = Events) async throws {
        try await events.fire(self)
    }
}

extension Listener {
    fileprivate func _handle(event: ObservedEvent) async throws {
        try await handle(event: event)
    }
}

extension Listener where Self: Job {
    fileprivate func _handle(event: Event) async throws {
        try await dispatch()
    }
}

private protocol AnyHandler {}
