public class Method<Req: RequestAllowed, Res: Codable> {
    public var wrappedValue: Endpoint<Req, Res>

    init(_ method: HTTPMethod, _ basePath: String) {
        self.wrappedValue = Endpoint<Req, Res>(method: method, basePath: basePath)
    }
}

public enum HTTPMethod: String {
    case CONNECT = "CONNECT"
    case DELETE = "DELETE"
    case GET = "GET"
    case HEAD = "HEAD"
    case OPTIONS = "OPTIONS"
    case PATCH = "PATCH"
    case POST = "POST"
    case PUT = "PUT"
    case TRACE = "TRACE"
}
