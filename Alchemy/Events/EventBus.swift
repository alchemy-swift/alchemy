import AsyncAlgorithms

public final class EventBus: IdentifiedService {
    public typealias Identifier = ServiceIdentifier<EventBus>

    private struct EventJob<E: Event & Codable>: Job, Codable {
        let event: E
        let listenerId: String

        func handle(context: JobContext) async throws {
            guard let listener = Events.listeners[listenerId] as? any QueueableListener<E> else {
                throw JobError("Unable to find registered listener of type `\(listenerId)` to handle a queued event.")
            }

            try await listener.handle(event: event)
        }
    }

    fileprivate var listeners: [String: any Listener] = [:]
    private let channel = AsyncChannel<Event>()

    public func stream<E: Event>(of: E.Type) -> AsyncStream<E> {
        channel
            .compactMap { $0 as? E }
            .stream
    }

    @discardableResult
    public func listen<E: Event>(_ event: E.Type, handler: @escaping (E) async throws -> Void) -> Task<Void, Error> {
        Task {
            for await event in stream(of: event) {
                try await handler(event)
            }
        }
    }

    @discardableResult
    public func register<L: Listener>(listener: L) -> Task<Void, Error> {
        listeners[L.registryId] = listener
        return Task {
            for await event in stream(of: L.ObservedEvent.self) {
                try await listener.handle(event: event)
            }
        }
    }

    @discardableResult
    public func register<L: QueueableListener>(listener: L) -> Task<Void, Error> {
        listeners[L.registryId] = listener
        return Task {
            for await event in stream(of: L.ObservedEvent.self) {
                if listener.shouldQueue(event: event) {
                    try await listener.handle(event: event)
                } else {
                    try await EventJob(event: event, listenerId: L.registryId)
                        .dispatch(on: listener.queue, channel: listener.channel)
                }
            }
        }
    }
    
    public func fire<E: Event>(_ event: E) {
        Task {
            await channel.send(event)
        }
    }
}

extension Listener {
    fileprivate static var registryId: String {
        name(of: Self.self)
    }
}
