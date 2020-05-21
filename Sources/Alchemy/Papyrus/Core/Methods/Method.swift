import NIOHTTP1

public class Method<Req, Res: Codable> {
    public var wrappedValue: Endpoint<Req, Res>

    init(_ method: HTTPMethod, _ basePath: String) {
        self.wrappedValue = Endpoint<Req, Res>(method: method, basePath: basePath)
    }
}
