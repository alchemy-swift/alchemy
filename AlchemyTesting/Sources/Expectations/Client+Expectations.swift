@testable import Alchemy
import AsyncHTTPClient
import Foundation

extension Client.Builder {
    public func expectNothingSent(sourceLocation: SourceLocation = #_sourceLocation) {
        let stubbedRequests = client.stubs?.stubbedRequests ?? []
        #expect(stubbedRequests.isEmpty, sourceLocation: sourceLocation)
    }
    
    public func expectSent(_ count: Int? = nil,
                           validate: ((Client.Request) throws -> Bool)? = nil,
                           sourceLocation: SourceLocation = #_sourceLocation) {
        let stubbedRequests = client.stubs?.stubbedRequests ?? []
        #expect(!stubbedRequests.isEmpty, sourceLocation: sourceLocation)
        if let count = count {
            #expect(client.stubs?.stubbedRequests.count == count, sourceLocation: sourceLocation)
        }
        
        if let validate = validate {
            var foundMatch = false
            for request in stubbedRequests where !foundMatch {
                #expect(throws: Never.self) { foundMatch = try validate(request) }
            }
            
            #expect(foundMatch, sourceLocation: sourceLocation)
        }
    }
}

extension Client.Request {
    public func hasHeader(_ name: HTTPField.Name, value: String? = nil) -> Bool {
        guard let header = headers[name] else {
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
    
    public func hasMethod(_ method: HTTPRequest.Method) -> Bool {
        self.method == method
    }
    
    public func hasBody(string: String) -> Bool {
        if let buffer = body?.buffer {
            return buffer.string == string
        } else {
            return false
        }
    }
}
