@propertyWrapper
public class PATCH<Req: RequestAllowed, Res: Codable> {
    public var wrappedValue: Endpoint<Req, Res>

    public init(_ basePath: String) {
        self.wrappedValue = Endpoint<Req, Res>(method: .PATCH, basePath: basePath)
    }
}
