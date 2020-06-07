public struct Endpoint<Req: RequestAllowed, Res: Codable> {
    public let method: HTTPReqMethod
    public var basePath: String
}

public protocol RequestAllowed: Codable {}
public protocol RequestCodable: RequestAllowed {}
public protocol BodyCodable: RequestAllowed {}
