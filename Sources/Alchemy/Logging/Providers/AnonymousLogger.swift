import Foundation

extension Logger {
    public init(label: String = "Alchemy", level: Logger.Level = .info, handler: @escaping (LogPayload) -> Void) {
        self.init(label: label, level: level, destination: AnonymousDestination(callback: handler))
    }

    public init(label: String = "Alchemy", 
                level: Logger.Level = .info,
                handler: @escaping (LogPayload) async throws -> Void,
                onError: @escaping (LogPayload, Error) -> Void = onErrorDefault) {
        self.init(label: label, level: level, destination: AnonymousDestination { payload in
            Task {
                do {
                    try await handler(payload)
                } catch {
                    onError(payload, error)
                }
            }
        })
    }

    public static func onErrorDefault(payload: LogPayload, error: Error) {
        print("Failed to log message from \(payload.label) with error: \(error).")
    }
}

private struct AnonymousDestination: LogDestination {
    let callback: (LogPayload) -> Void

    func log(payload: LogPayload) {
        callback(payload)
    }
}
