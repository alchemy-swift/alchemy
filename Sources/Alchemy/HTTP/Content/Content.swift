import Foundation

public protocol ContentValue {
    var string: String? { get }
    var bool: Bool? { get }
    var double: Double? { get }
    var int: Int? { get }
    var file: File? { get }
}

struct AnyContentValue: ContentValue {
    let value: Any
    
    var string: String? { value as? String }
    var bool: Bool? { value as? Bool }
    var int: Int? { value as? Int }
    var double: Double? { value as? Double }
    var file: File? { nil }
}

/// Utility making it easy to set or modify http content
@dynamicMemberLookup
public final class Content: Buildable {
    public enum Node {
        case array([Node])
        case dict([String: Node])
        case value(ContentValue)
        case null
        
        static func dict(_ dict: [String: Any]) -> Node {
            .dict(dict.mapValues(Node.any))
        }
        
        static func array(_ array: [Any]) -> Node {
            .array(array.map(Node.any))
        }
        
        static func any(_ value: Any) -> Node {
            if let array = value as? [Any] {
                return .array(array)
            } else if let dict = value as? [String: Any] {
                return .dict(dict)
            } else if case Optional<Any>.none = value {
                return .null
            } else {
                return .value(AnyContentValue(value: value))
            }
        }
    }
    
    enum Operator {
        case field(String)
        case index(Int)
        case flatten
    }
    
    enum State {
        case node(Node)
        case error(Error)
    }
    
    let state: State
    // The path taken to get here.
    let path: [Operator]
    
    public var string: String? { try? stringThrowing }
    public var stringThrowing: String { get throws { try unwrap(convertValue().string) } }
    public var int: Int? { try? intThrowing }
    public var intThrowing: Int { get throws { try unwrap(convertValue().int) } }
    public var bool: Bool? { try? boolThrowing }
    public var boolThrowing: Bool { get throws { try unwrap(convertValue().bool) } }
    public var double: Double? { try? doubleThrowing }
    public var doubleThrowing: Double { get throws { try unwrap(convertValue().double) } }
    public var file: File? { try? fileThrowing }
    public var fileThrowing: File { get throws { try unwrap(convertValue().file) } }
    public var array: [Content]? { try? convertArray() }
    public var arrayThrowing: [Content] { get throws { try convertArray() } }
    
    public var isNull: Bool { self == nil }
    
    public var error: Error? {
        guard case .error(let error) = state else { return nil }
        return error
    }
    
    var node: Node? {
        guard case .node(let node) = state else { return nil }
        return node
    }
    
    var value: ContentValue? {
        guard let node = node, case .value(let value) = node else { return nil }
        return value
    }

    init(root: Node, path: [Operator] = []) {
        self.state = .node(root)
        self.path = path
    }
    
    init(error: Error, path: [Operator] = []) {
        self.state = .error(error)
        self.path = path
    }
    
    // MARK: - Subscripts
    
    subscript(index: Int) -> Content {
        let newPath = path + [.index(index)]
        switch state {
        case .node(let node):
            guard case .array(let array) = node else {
                return Content(error: ContentError.notArray, path: newPath)
            }
            
            return Content(root: array[index], path: newPath)
        case .error(let error):
            return Content(error: error, path: newPath)
        }
    }
    
    subscript(field: String) -> Content {
        let newPath = path + [.field(field)]
        switch state {
        case .node(let node):
            guard case .dict(let dict) = node else {
                return Content(error: ContentError.notDictionary, path: newPath)
            }
            
            return Content(root: dict[field] ?? .null, path: newPath)
        case .error(let error):
            return Content(error: error, path: newPath)
        }
    }
    
    public subscript(dynamicMember member: String) -> Content {
        self[member]
    }
    
    subscript(operator: (Content, Content) -> Void) -> [Content] {
        let newPath = path + [.flatten]
        switch state {
        case .node(let node):
            switch node {
            case .null, .value:
                return [Content(error: ContentError.cantFlatten, path: newPath)]
            case .dict(let dict):
                return Array(dict.values).map { Content(root: $0, path: newPath) }
            case .array(let array):
                return array
                    .flatMap { content -> [Node] in
                        if case .array(let array) = content {
                            return array
                        } else if case .dict = content {
                            return [content]
                        } else {
                            return [.null]
                        }
                    }
                    .map { Content(root: $0, path: newPath) }
            }
        case .error(let error):
            return [Content(error: error, path: newPath)]
        }
    }
    
    static func *(lhs: Content, rhs: Content) {}
    
    static func ==(lhs: Content, rhs: Void?) -> Bool {
        switch lhs.state {
        case .node(let node):
            if case .null = node {
                return true
            } else {
                return false
            }
        case .error:
            return false
        }
    }
    
    private func convertArray() throws -> [Content] {
        switch state {
        case .node(let node):
            guard case .array(let array) = node else {
                throw ContentError.typeMismatch
            }
            
            return array.enumerated().map { Content(root: $1, path: path + [.index($0)]) }
        case .error(let error):
            throw error
        }
    }
    
    private func convertValue() throws -> ContentValue {
        switch state {
        case .node(let node):
            guard case .value(let val) = node else {
                throw ContentError.typeMismatch
            }
            
            return val
        case .error(let error):
            throw error
        }
    }
    
    private func unwrap<T>(_ value: T?) throws -> T {
        try value.unwrap(or: ContentError.typeMismatch)
    }
    
    public func decode<D: Decodable>(_ type: D.Type = D.self) throws -> D {
        try D(from: GenericDecoder(delegate: self))
    }
}

enum ContentError: Error {
    case unknownContentType(ContentType?)
    case emptyBody
    case cantFlatten
    case notDictionary
    case notArray
    case doesntExist
    case wasNull
    case typeMismatch
    case notSupported(String)
}

extension Content: DecoderDelegate {
    
    private func require<T>(_ optional: T?, key: CodingKey?) throws -> T {
        try optional.unwrap(or: DecodingError.valueNotFound(T.self, .init(codingPath: [key].compactMap { $0 }, debugDescription: "Value wasn`t available.")))
    }
    
    func decodeString(for key: CodingKey?) throws -> String {
        let value = key.map { self[$0.stringValue] } ?? self
        return try require(value.string, key: key)
    }
    
    func decodeDouble(for key: CodingKey?) throws -> Double {
        let value = key.map { self[$0.stringValue] } ?? self
        return try require(value.double, key: key)
    }
    
    func decodeInt(for key: CodingKey?) throws -> Int {
        let value = key.map { self[$0.stringValue] } ?? self
        return try require(value.int, key: key)
    }
    
    func decodeBool(for key: CodingKey?) throws -> Bool {
        let value = key.map { self[$0.stringValue] } ?? self
        return try require(value.bool, key: key)
    }
    
    func decodeNil(for key: CodingKey?) -> Bool {
        let value = key.map { self[$0.stringValue] } ?? self
        return value == nil
    }
    
    var allKeys: [String] {
        guard case .node(let node) = state, case .dict(let dict) = node else {
            return []
        }
        
        return Array(dict.keys)
    }
    
    func contains(key: CodingKey) -> Bool {
        guard case .node(let node) = state, case .dict(let dict) = node else {
            return false
        }
        
        return dict.keys.contains(key.stringValue)
    }
    
    func map(for key: CodingKey) -> DecoderDelegate {
        self[key.stringValue]
    }
    
    func array(for key: CodingKey?) throws -> [DecoderDelegate] {
        let val = key.map { self[$0.stringValue] } ?? self
        return try val.arrayThrowing.map { $0 }
    }
}

extension Array where Element == Content {
    var string: [String]? { try? stringThrowing }
    var stringThrowing: [String] { get throws { try map { try $0.stringThrowing } } }
    var int: [Int]? { try? intThrowing }
    var intThrowing: [Int] { get throws { try map { try $0.intThrowing } } }
    var bool: [Bool]? { try? boolThrowing }
    var boolThrowing: [Bool] { get throws { try map { try $0.boolThrowing } } }
    var double: [Double]? { try? doubleThrowing }
    var doubleThrowing: [Double] { get throws { try map { try $0.doubleThrowing } } }
    
    subscript(field: String) -> [Content] {
        return map { $0[field] }
    }
    
    subscript(dynamicMember member: String) -> [Content] {
        self[member]
    }
    
    func decode<D: Decodable>(_ type: D.Type = D.self) throws -> [D] {
        try map { try D(from: GenericDecoder(delegate: $0)) }
    }
}

extension Content: CustomStringConvertible {
    public var description: String {
        switch state {
        case .error(let error):
            return "Content(error: \(error)"
        case .node(let node):
            return createString(root: node)
        }
    }
    
    private func createString(root: Node?, tabs: String = "") -> String {
        var string = ""
        var tabs = tabs
        switch root {
        case .array(let array):
            tabs += "\t"
            if array.isEmpty {
                string.append("[]")
            } else {
                string.append("[\n")
                for (index, node) in array.enumerated() {
                    let comma = index == array.count - 1 ? "" : ","
                    string.append(tabs + createString(root: node, tabs: tabs) + "\(comma)\n")
                }
                tabs = String(tabs.dropLast(1))
                string.append("\(tabs)]")
            }
        case .value(let value):
            if let file = value.file {
                string.append("<\(file.name)>")
            } else if let bool = value.bool {
                string.append("\(bool)")
            } else if let int = value.int {
                string.append("\(int)")
            } else if let double = value.double {
                string.append("\(double)")
            } else if let stringVal = value.string {
                string.append("\"\(stringVal)\"")
            } else {
                string.append("\(value)")
            }
        case .dict(let dict):
            tabs += "\t"
            string.append("{\n")
            for (index, (key, node)) in dict.enumerated() {
                let comma = index == dict.count - 1 ? "" : ","
                string.append(tabs + "\"\(key)\": " + createString(root: node, tabs: tabs) + "\(comma)\n")
            }
            tabs = String(tabs.dropLast(1))
            string.append("\(tabs)}")
        case .null, .none:
            string.append("null")
        }
        
        return string
    }
}

extension Content {
    public static func == (lhs: Content, rhs: String) -> Bool {
        lhs.string == rhs
    }
    
    public static func == (lhs: Content, rhs: Int) -> Bool {
        lhs.int == rhs
    }
    
    public static func == (lhs: Content, rhs: Double) -> Bool {
        lhs.double == rhs
    }
    
    public static func == (lhs: Content, rhs: Bool) -> Bool {
        lhs.bool == rhs
    }
}
