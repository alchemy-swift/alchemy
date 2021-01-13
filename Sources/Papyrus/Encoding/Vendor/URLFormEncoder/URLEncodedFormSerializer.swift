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

import struct Foundation.CharacterSet

struct URLEncodedFormSerializer {
    let splitVariablesOn: Character
    let splitKeyValueOn: Character
    
    /// Create a new form-urlencoded data parser.
    init(splitVariablesOn: Character = "&", splitKeyValueOn: Character = "=") {
        self.splitVariablesOn = splitVariablesOn
        self.splitKeyValueOn = splitKeyValueOn
    }
    
    func serialize(_ data: URLEncodedFormData, codingPath: [CodingKey] = []) throws -> String {
        var entries: [String] = []
        let key = try codingPath.toURLEncodedKey()
        for value in data.values {
            if codingPath.count == 0 {
                try entries.append(value.asUrlEncoded())
            } else {
                try entries.append(key + String(splitKeyValueOn) + value.asUrlEncoded())
            }
        }
        for (key, child) in data.children {
            entries.append(try serialize(child, codingPath: codingPath + [_CodingKey(stringValue: key) as CodingKey]))
        }
        return entries.joined(separator: String(splitVariablesOn))
    }
    
    struct _CodingKey: CodingKey {
        var stringValue: String
        
        init(stringValue: String) {
            self.stringValue = stringValue
        }
        
        var intValue: Int?
        
        init?(intValue: Int) {
            self.intValue = intValue
            self.stringValue = intValue.description
        }
    }
}

extension Array where Element == CodingKey {
    func toURLEncodedKey() throws -> String {
        if count < 1 {
            return ""
        }
        return try self[0].stringValue.urlEncoded(codingPath: self) + self[1...].map({ (key: CodingKey) -> String in
            return try "[" + key.stringValue.urlEncoded(codingPath: self) + "]"
        }).joined()
    }
}

// MARK: Utilties

extension String {
    /// Prepares a `String` for inclusion in form-urlencoded data.
    func urlEncoded(codingPath: [CodingKey] = []) throws -> String {
        guard let result = self.addingPercentEncoding(
            withAllowedCharacters: _allowedCharacters
        ) else {
            throw EncodingError.invalidValue(self, EncodingError.Context(
                codingPath: codingPath,
                debugDescription: "Unable to add percent encoding to \(self)"
            ))
        }
        return result
    }
}

/// Characters allowed in form-urlencoded data.
private var _allowedCharacters: CharacterSet = {
    var allowed = CharacterSet.urlQueryAllowed
    // these symbols are reserved for url-encoded form
    allowed.remove(charactersIn: "?&=[];+")
    return allowed
}()
