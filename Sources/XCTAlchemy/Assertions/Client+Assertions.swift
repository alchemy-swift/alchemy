@testable import Alchemy
import AsyncHTTPClient
import XCTest

extension Client {
    public func assertNothingSent() {
        XCTAssert(stubbedRequests.isEmpty)
    }
    
    public func assertSent(_ count: Int? = nil, validate: ((HTTPClient.Request) throws -> Bool)? = nil) {
        XCTAssertFalse(stubbedRequests.isEmpty)
        if let count = count {
            XCTAssertEqual(stubbedRequests.count, count)
        }
        
        if let validate = validate {
            XCTAssertTrue(try stubbedRequests.reduce(false) {
                let validation = try validate($1)
                return $0 || validation
            })
        }
    }
}

extension HTTPClient.Request {
    public func hasHeader(_ name: String, value: String? = nil) -> Bool {
        guard let header = headers.first(name: name) else {
            return false
        }
        
        if let value = value {
            return header.stringValue == value
        } else {
            return true
        }
    }
    
    public func hasQuery<S: StringInitializable & Equatable>(_ name: String, value: S) -> Bool {
        let components = URLComponents(string: url.absoluteString)
        return components?.queryItems?.contains(where: { item in
            guard
                item.name == name,
                let stringValue = item.value,
                let itemValue = S(stringValue)
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
    
    public func hasBody(string: String) throws -> Bool {
        var byteBuffer: ByteBuffer? = nil
        try self.body?.stream(.init(closure: { data in
            switch data {
            case .byteBuffer(let buffer):
                byteBuffer = buffer
                return EmbeddedEventLoop().future()
            case .fileRegion:
                return EmbeddedEventLoop().future()
            }
        })).wait()
        
        if let byteBuffer = byteBuffer, let bodyString = byteBuffer.string() {
            return bodyString == string
        } else {
            return false
        }
    }
}
