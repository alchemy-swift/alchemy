import Alchemy

extension ContentInspector {
    // MARK: Header Assertions
    
    @discardableResult
    public func assertHeader(_ header: String, value: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let values = headers[header]
        XCTAssertFalse(values.isEmpty, file: file, line: line)
        for v in values {
            XCTAssertEqual(v, value, file: file, line: line)
        }
        
        return self
    }
    
    @discardableResult
    public func assertHeaderMissing(_ header: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        XCTAssert(headers[header].isEmpty, file: file, line: line)
        return self
    }
    
    @discardableResult
    public func assertLocation(_ uri: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        assertHeader("Location", value: uri, file: file, line: line)
    }
    
    // MARK: Body Assertions
    
    @discardableResult
    public func assertBody(_ string: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        guard let body = self.body else {
            XCTFail("Request body was nil.", file: file, line: line)
            return self
        }

        guard let decoded = body.string() else {
            XCTFail("Request body was not a String.", file: file, line: line)
            return self
        }
        
        XCTAssertEqual(decoded, string, file: file, line: line)
        return self
    }
    
    @discardableResult
    public func assertStream(_ assertChunk: @escaping (ByteBuffer) -> Void, file: StaticString = #filePath, line: UInt = #line) async throws -> Self {
        guard let body = self.body else {
            XCTFail("Request body was nil.", file: file, line: line)
            return self
        }
        
        try await body.stream.readAll(chunkHandler: assertChunk)
        return self
    }
    
    @discardableResult
    public func assertJson<D: Decodable & Equatable>(_ value: D, file: StaticString = #filePath, line: UInt = #line) -> Self {
        guard body != nil else {
            XCTFail("Request body was nil.", file: file, line: line)
            return self
        }
        
        XCTAssertNoThrow(try decode(D.self), file: file, line: line)
        guard let decoded = try? decode(D.self) else {
            return self
        }
        
        XCTAssertEqual(decoded, value, file: file, line: line)
        return self
    }
    
    // Convert to anything? String, Int, Bool, Double, Array, Object...
    @discardableResult
    public func assertJson(_ value: [String: Any], file: StaticString = #filePath, line: UInt = #line) -> Self {
        guard let body = self.body else {
            XCTFail("Request body was nil.", file: file, line: line)
            return self
        }
        
        guard let dict = try? body.decodeJSONDictionary() else {
            XCTFail("Request body wasn't a json object.", file: file, line: line)
            return self
        }
        
        XCTAssertEqual(NSDictionary(dictionary: dict), NSDictionary(dictionary: value), file: file, line: line)
        return self
    }
    
    @discardableResult
    public func assertEmpty(file: StaticString = #filePath, line: UInt = #line) -> Self {
        if body != nil {
            XCTFail("The response body was not empty \(body?.string() ?? "nil")", file: file, line: line)
        }
        
        return self
    }
}
