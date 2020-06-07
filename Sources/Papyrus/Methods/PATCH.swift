@propertyWrapper
public class PATCH<Req: RequestAllowed, Res: Codable>: BaseMethod<Req, Res> {
    // https://forums.swift.org/t/is-it-allowed-to-inherit-a-property-wrapper-class/28695
    public override var wrappedValue: Endpoint<Req, Res> { didSet {} }

    public init(_ basePath: String) {
        super.init(.PATCH, basePath)
    }
}
