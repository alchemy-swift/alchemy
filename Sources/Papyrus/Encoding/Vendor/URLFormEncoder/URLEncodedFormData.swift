/// The MIT License (MIT)
///
/// Copyright (c) 2020 Qutheory, LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in all
/// copies or substantial portions of the Software.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
/// SOFTWARE.
///
/// Courtesy of https://github.com/vapor/vapor

/// Keeps track if the string was percent encoded or not.
/// Prevents double encoding/double decoding
enum URLQueryFragment: ExpressibleByStringLiteral, Equatable {
    init(stringLiteral: String) {
        self = .urlDecoded(stringLiteral)
    }
    
    case urlEncoded(String)
    case urlDecoded(String)
    
    /// Returns the URL Encoded version
    func asUrlEncoded() throws -> String {
        switch self {
        case .urlEncoded(let encoded):
            return encoded
        case .urlDecoded(let decoded):
            return try decoded.urlEncoded()
        }
    }
    
    /// Returns the URL Decoded version
    func asUrlDecoded() throws -> String {
        switch self {
        case .urlEncoded(let encoded):
            guard let decoded = encoded.removingPercentEncoding else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Unable to remove percent encoding for \(encoded)"))
            }
            return decoded
        case .urlDecoded(let decoded):
            return decoded
        }
    }
    
    /// Do comparison and hashing using the decoded version as there are multiple ways something can be encoded.
    /// Certain characters that are not typically encoded could have been encoded making string comparisons between two encodings not work
    static func == (lhs: URLQueryFragment, rhs: URLQueryFragment) -> Bool {
        do {
            return try lhs.asUrlDecoded() == rhs.asUrlDecoded()
        } catch {
            return false
        }
    }
    
    func hash(into: inout Hasher) {
        do {
            try self.asUrlDecoded().hash(into: &into)
        } catch {
            print("Error hashing: \(error)")
        }
    }
}

/// Represents application/x-www-form-urlencoded encoded data.
internal struct URLEncodedFormData: ExpressibleByArrayLiteral, ExpressibleByStringLiteral, ExpressibleByDictionaryLiteral, Equatable {
    var values: [URLQueryFragment]
    var children: [String: URLEncodedFormData]
    
    var hasOnlyValues: Bool {
        return children.count == 0
    }
    
    var allChildKeysAreSequentialIntegers: Bool {
        for i in 0...children.count-1 {
            if !children.keys.contains(String(i)) {
                return false
            }
        }
        return true
    }

    init(values: [URLQueryFragment] = [], children: [String: URLEncodedFormData] = [:]) {
        self.values = values
        self.children = children
    }
    
    init(stringLiteral: String) {
        self.values = [.urlDecoded(stringLiteral)]
        self.children = [:]
    }
    
    init(arrayLiteral: String...) {
        self.values = arrayLiteral.map({ (s: String) -> URLQueryFragment in
            return .urlDecoded(s)
        })
        self.children = [:]
    }
    
    init(dictionaryLiteral: (String, URLEncodedFormData)...) {
        self.values = []
        self.children = Dictionary(uniqueKeysWithValues: dictionaryLiteral)
    }
        
    mutating func set(value: URLQueryFragment, forPath path: [String]) {
        guard let firstElement = path.first else {
            self.values.append(value)
            return
        }
        var child: URLEncodedFormData
        if let existingChild = self.children[firstElement] {
            child = existingChild
        } else {
            child = []
        }
        child.set(value: value, forPath: Array(path[1...]))
        self.children[firstElement] = child
    }
}
