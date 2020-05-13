import NIOHTTP1

public struct Endpoint<Req, Res: Codable> {
    public let method: HTTPMethod
    public var basePath: String
}
