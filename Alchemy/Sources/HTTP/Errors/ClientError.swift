/// An error encountered when making a request with `Client`.
public struct ClientError: Error, CustomStringConvertible {
    /// What went wrong.
    public let message: String
    /// The associated `Client.Request`.
    public let request: Client.Request
    /// The associated `Client.Response`.
    public let response: Client.Response

    // MARK: - CustomStringConvertible

    public var description: String {
        return """
            *** HTTP Client Error ***
            \(message)

            *** Request ***
            URL: \(request.method.rawValue) \(request.url.absoluteString)
            Headers: [
                \(debugString(for: request.headers))
            ]
            Body: \(debugString(for: request.body))

            *** Response ***
            Status: \(response.status.code) \(response.status.reasonPhrase)
            Headers: [
                \(debugString(for: response.headers))
            ]
            Body: \(debugString(for: response.body))
            """
    }

    private func debugString(for headers: HTTPFields) -> String {
        if Env.logFullClientErrors || Env.isDebug {
            return headers.map { "\($0.name): \($0.value)" }.joined(separator: "\n    ")
        } else {
            return headers.map { "\($0.name)" }.joined(separator: "\n    ")
        }
    }

    private func debugString(for content: Bytes?) -> String {
        guard let content else {
            return "<empty>"
        }

        if Env.logFullClientErrors || Env.isDebug {
            switch content {
            case .buffer(let buffer):
                return buffer.string
            case .stream:
                return "<stream>"
            }
        } else {
            switch content {
            case .buffer(let buffer):
                return "<\(buffer.readableBytes) bytes>"
            case .stream:
                return "<stream>"
            }
        }
    }
}

extension Environment {
    @Env public var logFullClientErrors = false
}
