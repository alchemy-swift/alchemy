import Alchemy
import XCTest

public protocol ResponseAssertable {
    var status: HTTPResponseStatus { get }
    var headers: HTTPHeaders { get }
    var body: HTTPBody? { get }
}

extension Response: ResponseAssertable {}
extension ClientResponse: ResponseAssertable {}

extension ResponseAssertable {
    // MARK: Status Assertions
    
    @discardableResult
    public func assertCreated(file: StaticString = #filePath, line: UInt = #line) -> Self {
        XCTAssertEqual(status, .created, file: file, line: line)
        return self
    }
    
    @discardableResult
    public func assertForbidden(file: StaticString = #filePath, line: UInt = #line) -> Self {
        XCTAssertEqual(status, .forbidden, file: file, line: line)
        return self
    }
    
    @discardableResult
    public func assertNotFound(file: StaticString = #filePath, line: UInt = #line) -> Self {
        XCTAssertEqual(status, .notFound, file: file, line: line)
        return self
    }
    
    @discardableResult
    public func assertOk(file: StaticString = #filePath, line: UInt = #line) -> Self {
        XCTAssertEqual(status, .ok, file: file, line: line)
        return self
    }
    
    @discardableResult
    public func assertRedirect(to uri: String? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
        XCTAssertTrue((300...399).contains(status.code), file: file, line: line)
        
        if let uri = uri {
            assertLocation(uri, file: file, line: line)
        }
        
        return self
    }
    
    @discardableResult
    public func assertStatus(_ status: HTTPResponseStatus, file: StaticString = #filePath, line: UInt = #line) -> Self {
        XCTAssertEqual(self.status, status, file: file, line: line)
        return self
    }
    
    @discardableResult
    public func assertStatus(_ code: UInt, file: StaticString = #filePath, line: UInt = #line) -> Self {
        XCTAssertEqual(status.code, code, file: file, line: line)
        return self
    }
    
    @discardableResult
    public func assertSuccessful(file: StaticString = #filePath, line: UInt = #line) -> Self {
        XCTAssertTrue((200...299).contains(status.code), file: file, line: line)
        return self
    }
    
    @discardableResult
    public func assertUnauthorized(file: StaticString = #filePath, line: UInt = #line) -> Self {
        XCTAssertEqual(status, .unauthorized, file: file, line: line)
        return self
    }
    
    // MARK: Header Assertions
    
    @discardableResult
    public func assertHeader(_ header: String, value: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        XCTAssertTrue(headers[header].contains(value), file: file, line: line)
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

        guard let decoded = body.decodeString() else {
            XCTFail("Request body was not a String.", file: file, line: line)
            return self
        }
        
        XCTAssertEqual(decoded, string, file: file, line: line)
        return self
    }
    
    @discardableResult
    public func assertJson<D: Decodable & Equatable>(_ value: D, file: StaticString = #filePath, line: UInt = #line) -> Self {
        guard let body = self.body else {
            XCTFail("Request body was nil.", file: file, line: line)
            return self
        }
        
        XCTAssertNoThrow(try body.decodeJSON(as: D.self), file: file, line: line)
        guard let decoded = try? body.decodeJSON(as: D.self) else {
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
            XCTFail("The response body was not empty \(body?.decodeString() ?? "nil")", file: file, line: line)
        }
        
        return self
    }
}
