@testable import Alchemy
import AsyncHTTPClient
import XCTest

extension Client {
    public func assertNothingSent(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssert(stubbedRequests.isEmpty, file: file, line: line)
    }
    
    public func assertSent(
        _ count: Int? = nil,
        validate: ((Client.Request) -> Bool)? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertFalse(stubbedRequests.isEmpty, file: file, line: line)
        if let count = count {
            XCTAssertEqual(stubbedRequests.count, count, file: file, line: line)
        }
        
        if let validate = validate {
            var foundMatch = false
            for request in stubbedRequests where !foundMatch {
                foundMatch = validate(request)
            }
            
            AssertTrue(foundMatch, file: file, line: line)
        }
    }
}

extension Client.Request {
    public func hasHeader(_ name: String, value: String? = nil) -> Bool {
        guard let header = headers.first(name: name) else {
            return false
        }
        
        if let value = value {
            return header == value
        } else {
            return true
        }
    }
    
    public func hasQuery<L: LosslessStringConvertible & Equatable>(_ name: String, value: L) -> Bool {
        let components = URLComponents(string: url.absoluteString)
        return components?.queryItems?.contains(where: { item in
            guard
                item.name == name,
                let stringValue = item.value,
                let itemValue = L(stringValue)
            else {
                return false
            }
            
            return itemValue == value
        }) ?? false
    }
    
    public func hasPath(_ path: String) -> Bool {
        URLComponents(string: url.absoluteString)?.path == path
    }
    
    public func hasMethod(_ method: HTTPMethod) -> Bool {
        self.method == method
    }
    
    public func hasBody(string: String) -> Bool {
        if let byteBuffer = body?.buffer, let bodyString = byteBuffer.string() {
            return bodyString == string
        } else {
            return false
        }
    }
}
