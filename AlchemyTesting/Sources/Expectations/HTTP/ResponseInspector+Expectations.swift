import Alchemy

extension Response: ResponseInspector {
    public var container: Container { Container() }
}

extension ResponseInspector {

    // MARK: Status Expectations

    @discardableResult
    public func expectCreated(sourceLocation: SourceLocation = #_sourceLocation) -> Self {
        #expect(status == .created, sourceLocation: sourceLocation)
        return self
    }

    @discardableResult
    public func expectForbidden(sourceLocation: SourceLocation = #_sourceLocation) -> Self {
        #expect(status == .forbidden, sourceLocation: sourceLocation)
        return self
    }

    @discardableResult
    public func expectNotFound(sourceLocation: SourceLocation = #_sourceLocation) -> Self {
        #expect(status == .notFound, sourceLocation: sourceLocation)
        return self
    }

    @discardableResult
    public func expectOk(sourceLocation: SourceLocation = #_sourceLocation) -> Self {
        #expect(status == .ok, sourceLocation: sourceLocation)
        return self
    }

    @discardableResult
    public func expectRedirect(to uri: String? = nil, sourceLocation: SourceLocation = #_sourceLocation) -> Self {
        #expect((300...399).contains(status.code), sourceLocation: sourceLocation)

        if let uri = uri {
            expectLocation(uri)
        }

        return self
    }

    @discardableResult
    public func expectStatus(_ status: HTTPResponse.Status, sourceLocation: SourceLocation = #_sourceLocation) -> Self {
        #expect(self.status == status, sourceLocation: sourceLocation)
        return self
    }

    @discardableResult
    public func expectStatus(_ code: Int, sourceLocation: SourceLocation = #_sourceLocation) -> Self {
        #expect(status.code == code, sourceLocation: sourceLocation)
        return self
    }

    @discardableResult
    public func expectSuccessful(sourceLocation: SourceLocation = #_sourceLocation) -> Self {
        #expect((200...299).contains(status.code), sourceLocation: sourceLocation)
        return self
    }

    @discardableResult
    public func expectUnauthorized(sourceLocation: SourceLocation = #_sourceLocation) -> Self {
        #expect(status == .unauthorized, sourceLocation: sourceLocation)
        return self
    }
}
