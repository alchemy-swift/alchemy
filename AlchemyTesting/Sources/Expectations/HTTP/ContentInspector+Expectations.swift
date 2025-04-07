import Alchemy
import Foundation

extension HTTPInspector {
    // MARK: Header Expectations

    @discardableResult
    public func expectHeader(_ name: HTTPField.Name,
                             value: String,
                             sourceLocation: SourceLocation = #_sourceLocation) -> Self {
        let values = headers[values: name]
        #expect(!values.isEmpty, sourceLocation: sourceLocation)
        for v in values {
            #expect(v == value, sourceLocation: sourceLocation)
        }

        return self
    }
    
    @discardableResult
    public func expectHeaderMissing(_ header: HTTPField.Name, sourceLocation: SourceLocation = #_sourceLocation) -> Self {
        #expect(headers[header] == nil, sourceLocation: sourceLocation)
        return self
    }
    
    @discardableResult
    public func expectLocation(_ uri: String, sourceLocation: SourceLocation = #_sourceLocation) -> Self {
        expectHeader(.location, value: uri, sourceLocation: sourceLocation)
    }
    
    // MARK: Body Expectations

    @discardableResult
    public func expectBody(_ string: String, sourceLocation: SourceLocation = #_sourceLocation) -> Self {
        #expect(body?.string == string, sourceLocation: sourceLocation)
        return self
    }
    
    @discardableResult
    public func expectStream(_ expectChunk: @escaping (ByteBuffer) -> Void,
                             sourceLocation: SourceLocation = #_sourceLocation) async throws -> Self {
        guard let body else {
            Issue.record("Request body was nil.")
            return self
        }

        for try await chunk in body.stream {
            expectChunk(chunk)
        }

        return self
    }
    
    @discardableResult
    public func expectJson<D: Decodable & Equatable>(_ value: D, sourceLocation: SourceLocation = #_sourceLocation) -> Self {
        guard body != nil else {
            Issue.record("Request body was nil.", sourceLocation: sourceLocation)
            return self
        }

        #expect(throws: Never.self, sourceLocation: sourceLocation) { try decode(D.self) }
        guard let decoded = try? decode(D.self) else { return self }
        #expect(decoded == value, sourceLocation: sourceLocation)
        return self
    }
    
    // Convert to anything? String, Int, Bool, Double, Array, Object...
    @discardableResult
    public func expectJsonDict(_ value: [String: Any], sourceLocation: SourceLocation = #_sourceLocation) -> Self {
        guard let body else {
            Issue.record("Request body was nil.", sourceLocation: sourceLocation)
            return self
        }
        
        guard let dict = try? JSONSerialization.jsonObject(with: body.data, options: []) as? [String: Any] else {
            Issue.record("Request body wasn't a json object.", sourceLocation: sourceLocation)
            return self
        }
        
        #expect(NSDictionary(dictionary: dict) == NSDictionary(dictionary: value), sourceLocation: sourceLocation)
        return self
    }

    @discardableResult
    public func expectBodyHasFields(_ fields: String..., sourceLocation: SourceLocation = #_sourceLocation) -> Self {
        guard let body else {
            Issue.record("Request body was nil.", sourceLocation: sourceLocation)
            return self
        }

        guard let dict = try? JSONSerialization.jsonObject(with: body.data, options: []) as? [String: Any] else {
            Issue.record("Request body wasn't a json object.", sourceLocation: sourceLocation)
            return self
        }

        for field in fields {
            #expect(dict.keys.contains(field), sourceLocation: sourceLocation)
        }
        
        return self
    }

    @discardableResult
    public func expectEmpty(sourceLocation: SourceLocation = #_sourceLocation) -> Self {
        #expect(body == nil, sourceLocation: sourceLocation)
        return self
    }
}
