/// Copyright (c) 2014-2020 Alamofire Software Foundation (http://alamofire.org/)
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.
///
/// Courtesy of https://github.com/Alamofire/Alamofire .
import Foundation

/// Need to detect if types are optional so we can avoid putting nil in a query.
private protocol AnyOptional {
    /// The erased, unwrapped value of this optional.
    var unwrappedAny: Any? { get }
}

extension Optional: AnyOptional {
    var unwrappedAny: Any? {
        self.map { $0 as Any }
    }
}

extension String {
    /// Creates a percent-escaped, URL encoded query string components from the given key-value pair recursively.
    ///
    /// - Parameters:
    ///   - key:   Key of the query component.
    ///   - value: Value of the query component.
    ///
    /// - Returns: The percent-escaped, URL encoded query string components.
    public static func queryComponents(fromKey key: String, value: Any) -> [(String, String)] {
        var components: [(String, String)] = []

        if let dictionary = value as? [String: Any] {
            for (nestedKey, value) in dictionary {
                components += self.queryComponents(fromKey: "\(key)[\(nestedKey)]", value: value)
            }
        } else if let array = value as? [Any] {
            for value in array {
                components += self.queryComponents(fromKey: ArrayEncoding.brackets.encode(key: key), value: value)
            }
        } else if let value = value as? NSNumber {
            components.append((self.escape(key), self.escape("\(value)")))
        } else if let bool = value as? Bool {
            components.append((self.escape(key), self.escape(BoolEncoding.numeric.encode(value: bool))))
        } else if let optional = value as? AnyOptional {
            if let unwrapped = optional.unwrappedAny {
                components += self.queryComponents(fromKey: key, value: unwrapped)
            }
        } else {
            components.append((self.escape(key), self.escape("\(value)")))
        }

        return components
    }


    /// Creates a percent-escaped string following RFC 3986 for a query string key or value.
    ///
    /// - Parameter string: `String` to be percent-escaped.
    ///
    /// - Returns:          The percent-escaped `String`.
    public static func escape(_ string: String) -> String {
        return string.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed) ?? string
    }
}

public extension CharacterSet {
    /// Creates a CharacterSet from RFC 3986 allowed characters.
    ///
    /// RFC 3986 states that the following characters are "reserved" characters.
    ///
    /// - General Delimiters: ":", "#", "[", "]", "@", "?", "/"
    /// - Sub-Delimiters: "!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "="
    ///
    /// In RFC 3986 - Section 3.4, it states that the "?" and "/" characters should not be escaped to allow
    /// query strings to include a URL. Therefore, all "reserved" characters with the exception of "?" and "/"
    /// should be percent-escaped in the query string.
    static let afURLQueryAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        let encodableDelimiters = CharacterSet(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")

        return CharacterSet.urlQueryAllowed.subtracting(encodableDelimiters)
    }()
}

/// Configures how `Array` parameters are encoded.
public enum ArrayEncoding {
    /// An empty set of square brackets is appended to the key for every value. This is the default behavior.
    case brackets
    /// No brackets are appended. The key is encoded as is.
    case noBrackets

    func encode(key: String) -> String {
        switch self {
        case .brackets:
            return "\(key)[]"
        case .noBrackets:
            return key
        }
    }
}

/// Configures how `Bool` parameters are encoded.
public enum BoolEncoding {
    /// Encode `true` as `1` and `false` as `0`. This is the default behavior.
    case numeric
    /// Encode `true` and `false` as string literals.
    case literal

    func encode(value: Bool) -> String {
        switch self {
        case .numeric:
            return value ? "1" : "0"
        case .literal:
            return value ? "true" : "false"
        }
    }
}
