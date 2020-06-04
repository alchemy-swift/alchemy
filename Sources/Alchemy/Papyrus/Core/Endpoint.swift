import NIOHTTP1

public struct Endpoint<Req: RequestAllowed, Res: Codable> {
    public let method: HTTPMethod
    public var basePath: String
}

public protocol RequestAllowed: Codable {}
public protocol RequestCodable: RequestAllowed {}
public protocol RequestBodyCodable: RequestAllowed {}
