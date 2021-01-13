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

/// Parses a URL Query `single=value&arr=1&arr=2&obj[key]=objValue` into
internal struct URLEncodedFormParser {
    let splitVariablesOn: Character
    let splitKeyValueOn: Character
    
    /// Create a new form-urlencoded data parser.
    init(splitVariablesOn: Character = "&", splitKeyValueOn: Character = "=") {
        self.splitVariablesOn = splitVariablesOn
        self.splitKeyValueOn = splitKeyValueOn
    }
    
    func parse(_ query: String) throws -> URLEncodedFormData {
        let plusDecodedQuery = query.replacingOccurrences(of: "+", with: "%20")
        var result: URLEncodedFormData = []
        for pair in plusDecodedQuery.split(separator: splitVariablesOn) {
            let kv = pair.split(
                separator: self.splitKeyValueOn,
                maxSplits: 1, // max 1, `foo=a=b` should be `"foo": "a=b"`
                omittingEmptySubsequences: false
            )
            switch kv.count {
            case 1:
                let value = String(kv[0])
                result.set(value: .urlEncoded(value), forPath: [])
            case 2:
                let key = kv[0]
                let value = String(kv[1])
                result.set(value: .urlEncoded(value), forPath: try parseKey(key: Substring(key)))
            default:
                //Empty `&&`
                continue
            }
        }
        return result
    }
    
    func parseKey(key: Substring) throws -> [String] {
        var path = [String]()
        for var element in key.split(separator: "[") {
            if path.count > 0 { //First one is not wrapped with `[]`
                guard element.last == "]" else {
                    throw URLEncodedFormError.malformedKey(key: .init(key))
                }
                element = element.prefix(element.count-1) //Remove the `]`
            }
            guard let percentDecodedElement = element.removingPercentEncoding else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Unable to remove percent encoding for \(element)"))
            }
            path.append(percentDecodedElement)
        }
        return path
    }
}

