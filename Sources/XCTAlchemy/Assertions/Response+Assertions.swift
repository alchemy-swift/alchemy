import Alchemy
import XCTest

extension Response {
    // MARK: Status Assertions
    
    public func assertCreated() {
        XCTAssertEqual(status, .created)
    }
    
    public func assertForbidden() {
        XCTAssertEqual(status, .forbidden)
    }
    
    public func assertNotFound() {
        XCTAssertEqual(status, .notFound)
    }
    
    public func assertOk() {
        XCTAssertEqual(status, .ok)
    }
    
    public func assertRedirect(to uri: String? = nil) {
        XCTAssertTrue((300...399).contains(status.code))
        
        if let uri = uri {
            assertLocation(uri)
        }
    }
    
    public func assertStatus(_ status: HTTPResponseStatus) {
        XCTAssertEqual(self.status, status)
    }
    
    public func assertStatus(_ code: UInt) {
        XCTAssertEqual(status.code, code)
    }
    
    public func assertSuccessful() {
        XCTAssertTrue((200...299).contains(status.code))
    }
    
    public func assertUnauthorized() {
        XCTAssertEqual(status, .unauthorized)
    }
    
    // MARK: Header Assertions
    
    public func assertHeader(_ header: String, value: String) {
        XCTAssertTrue(headers[header].contains(value))
    }
    
    public func assertHeaderMissing(_ header: String) {
        XCTAssert(headers[header].isEmpty)
    }
    
    public func assertLocation(_ uri: String) {
        assertHeader("Location", value: uri)
    }
    
    // MARK: Body Assertions
    
    public func assertJson<D: Decodable & Equatable>(_ value: D) {
        guard let body = self.body else {
            return XCTFail("Request body was nil.")
        }
        
        XCTAssertNoThrow(try body.decodeJSON(as: D.self))
        guard let decoded = try? body.decodeJSON(as: D.self) else {
            return
        }
        
        XCTAssertEqual(decoded, value)
    }
    
    // Convert to anything? String, Int, Bool, Double, Array, Object...
    public func assertJson(_ value: [String: Any]) {
        guard let body = self.body else {
            return XCTFail("Request body was nil.")
        }
        
        guard let dict = try? body.decodeJSONDictionary() else {
            return XCTFail("Request body wasn't a json object.")
        }
        
        XCTAssertEqual(NSDictionary(dictionary: dict), NSDictionary(dictionary: value))
    }
}
