import NIOConcurrencyHelpers

public final class EventBus: Service {
    public typealias Identifier = ServiceIdentifier<EventBus>

    public typealias Handler<E: Event> = (E) async throws -> Void
    private typealias AnyHandler = (Event) async throws -> Void

    private var listeners: [String: any Listener] = [:]
    private var handlers: [String: [AnyHandler]] = [:]
    private let lock = NIOLock()

    public func on<E: Event>(_ event: E.Type, handler: @escaping Handler<E>) {
        lock.withLock {
            handlers[E.registrationKey, default: []] += [convertHandler(handler)]
        }
    }

    public func register<L: Listener>(listener: L) {
        lock.withLock {
            handlers[L.ObservedEvent.registrationKey, default: []] += [convertHandler(listener.handle)]
            listeners[L.registryId] = listener
        }
    }

    public func register<L: QueueableListener>(listener: L) {
        lock.withLock {
            Jobs.register(EventJob<L.ObservedEvent>.self)
            handlers[L.ObservedEvent.registrationKey, default: []] += [convertHandler(listener.dispatch)]
            listeners[L.registryId] = listener
        }
    }
    
    public func fire<E: Event>(_ event: E) async throws {
        let handlers = lock.withLock { self.handlers[E.registrationKey] ?? [] }
        for handle in handlers {
            try await handle(event)
        }
    }

    fileprivate func lookupListener<E: Event>(_ id: String, eventType: E.Type = E.self) throws -> any Listener<E> {
        guard let listener = Events.listeners[id] as? any Listener<E> else {
            throw JobError("Unable to find registered listener of type `\(id)` to handle a queued event.")
        }

        return listener
    }

    private func convertHandler<E: Event>(_ handler: @escaping Handler<E>) -> AnyHandler {
        return { event in
            guard let event = event as? E else {
                Log.error("Event handler type mismatch for \(E.registrationKey)!")
                return
            }

            try await handler(event)
        }
    }
}

private struct EventJob<E: Event & Codable>: Job, Codable {
    let event: E
    let listenerId: String

    func handle(context: JobContext) async throws {
        try await Events.lookupListener(listenerId, eventType: E.self).handle(event: event)
    }
}

extension QueueableListener {
    fileprivate func dispatch(event: ObservedEvent) async throws {
        guard shouldQueue(event: event) else {
            try await handle(event: event)
            return
        }

        try await EventJob(event: event, listenerId: Self.registryId)
            .dispatch(on: queue, channel: channel)
    }
}

extension Listener {
    fileprivate static var registryId: String {
        name(of: Self.self)
    }
}
