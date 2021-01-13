/// Represents a DELETE `Endpoint`.
@propertyWrapper
public class DELETE<Req: EndpointRequest, Res: Codable> {
    /// A DELETE REST endpoint with the given path.
    public var wrappedValue: Endpoint<Req, Res>

    /// Initialize with a path.
    ///
    /// - Parameter path: The path of the endpoint.
    public init(_ path: String) {
        self.wrappedValue = Endpoint<Req, Res>(method: .delete, path: path)
    }
    
    /// Wraps access of the `wrappedValue` when this propery is on a
    /// reference type. Sets the `baseURL` of the endpoint when
    /// accessed based on the enclosing instance.
    public static subscript<EnclosingSelf: EndpointGroup>(
        _enclosingInstance object: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Endpoint<Req, Res>>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, DELETE<Req, Res>>
    ) -> Endpoint<Req, Res> {
        get { object[keyPath: storageKeyPath].wrappedValue.with(baseURL: object.baseURL) }
        // This setter is needed so that the propert wrapper will have
        // a `WritableKeyPath` for using this subscript.
        set { fatalError("Endpoints should not be set.") }
    }
}
