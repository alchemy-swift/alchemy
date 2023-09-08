import Alchemy
import XCTest

extension Response: ResponseInspector {
    public var container: Container { Container() }
}

extension ResponseInspector {
    
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
}
