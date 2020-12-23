@propertyWrapper
public class PUT<Req: EndpointRequest, Res: Codable> {
    public var wrappedValue: Endpoint<Req, Res>

    public init(_ basePath: String) {
        self.wrappedValue = Endpoint<Req, Res>(method: .put, path: basePath)
    }
    
    public static subscript<EnclosingSelf: EndpointGroup>(
        _enclosingInstance object: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Endpoint<Req, Res>>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, PUT<Req, Res>>
    ) -> Endpoint<Req, Res> {
        get { object[keyPath: storageKeyPath].wrappedValue.with(baseURL: object.baseURL) }
        // This setter is needed so that the propert wrapper will have a `WritableKeyPath` for using
        // this subscript.
        set { fatalError("Endpoints should not be set.") }
    }
}
