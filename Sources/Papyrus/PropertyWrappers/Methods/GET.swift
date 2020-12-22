@propertyWrapper
public class GET<Req: RequestAllowed, Res: Codable> {
    public var wrappedValue: Endpoint<Req, Res>

    public init(_ basePath: String) {
        self.wrappedValue = Endpoint<Req, Res>(method: .GET, basePath: basePath)
    }
}
