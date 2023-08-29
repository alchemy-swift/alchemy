import Foundation

public protocol ContentValue {
    var string: String? { get }
    var bool: Bool? { get }
    var double: Double? { get }
    var int: Int? { get }
    var file: File? { get }
}

/// Utility making it easy to set or modify HTTP content.
@dynamicMemberLookup
public final class Content: Buildable {
    public enum State {
        public enum Node {
            case value(ContentValue)
            case dictionary([String: Node])
            case array([Node])
            case null
        }

        case node(Node)
        case error(Error)
    }

    public enum Operator {
        case field(String)
        case index(Int)
        case flatten
    }

    /// The state of this node; either an error or a value.
    public let state: State
    
    /// The path taken to get here.
    public let path: [Operator]

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
    public var arrayThrowing: [Content] { get throws { try unwrap(convertArray()) } }
    public var isNull: Bool { self == nil }
    public var error: Error? {
        guard case .error(let error) = state else { return nil }
        return error
    }
    
    public init(node: State.Node, path: [Operator] = []) {
        self.state = .node(node)
        self.path = path
    }
    
    public init(error: Error, path: [Operator] = []) {
        self.state = .error(error)
        self.path = path
    }

    public func decode<D: Decodable>(_ type: D.Type = D.self) throws -> D {
        try D(from: GenericDecoder(delegate: self))
    }

    private func convertArray() throws -> [Content] {
        switch state {
        case .node(.array(let array)):
            return array.enumerated().map { Content(node: $1, path: path + [.index($0)]) }
        case .error(let error):
            throw error
        default:
            throw ContentError.typeMismatch
        }
    }

    private func convertValue() throws -> ContentValue {
        switch state {
        case .node(.value(let value)):
            return value
        case .error(let error):
            throw error
        default:
            throw ContentError.typeMismatch
        }
    }

    private func unwrap<T>(_ value: T?) throws -> T {
        guard let value else { throw ContentError.typeMismatch }
        return value
    }

    // MARK: Subscripts
    
    public subscript(index: Int) -> Content {
        let newPath = path + [.index(index)]
        switch state {
        case .node(let node):
            guard case .array(let array) = node else {
                return Content(error: ContentError.notArray, path: newPath)
            }
            
            return Content(node: array[index], path: newPath)
        case .error(let error):
            return Content(error: error, path: newPath)
        }
    }
    
    public subscript(field: String) -> Content {
        let newPath = path + [.field(field)]
        switch state {
        case .node(let node):
            guard case .dictionary(let dict) = node else {
                return Content(error: ContentError.notDictionary, path: newPath)
            }
            
            return Content(node: dict[field] ?? .null, path: newPath)
        case .error(let error):
            return Content(error: error, path: newPath)
        }
    }
    
    public subscript(dynamicMember member: String) -> Content {
        self[member]
    }
    
    public subscript(operator: (Content, Content) -> Void) -> [Content] {
        let newPath = path + [.flatten]
        switch state {
        case .node(let node):
            switch node {
            case .null, .value:
                return [Content(error: ContentError.cantFlatten, path: newPath)]
            case .dictionary(let dict):
                return Array(dict.values).map { Content(node: $0, path: newPath) }
            case .array(let array):
                return array
                    .flatMap { content in
                        if case .array(let array) = content {
                            return array
                        } else if case .dictionary = content {
                            return [content]
                        } else {
                            return [.null]
                        }
                    }
                    .map { Content(node: $0, path: newPath) }
            }
        case .error(let error):
            return [Content(error: error, path: newPath)]
        }
    }

    // MARK: Operators

    public static func * (lhs: Content, rhs: Content) {}

    public static func == (lhs: Content, rhs: Void?) -> Bool {
        switch lhs.state {
        case .node(let node):
            guard case .null = node else {
                return false
            }

            return true
        case .error:
            return false
        }
    }

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

// MARK: GenericDecoderDelegate

extension Content: GenericDecoderDelegate {
    var allKeys: [String] {
        guard case .node(let node) = state, case .dictionary(let dict) = node else {
            return []
        }

        return Array(dict.keys)
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
    
    func contains(key: CodingKey) -> Bool {
        guard case .node(let node) = state, case .dictionary(let dict) = node else {
            return false
        }
        
        return dict.keys.contains(key.stringValue)
    }
    
    func dictionary(for key: CodingKey) -> GenericDecoderDelegate {
        self[key.stringValue]
    }
    
    func array(for key: CodingKey?) throws -> [GenericDecoderDelegate] {
        let val = key.map { self[$0.stringValue] } ?? self
        return try val.arrayThrowing.map { $0 }
    }

    private func require<T>(_ optional: T?, key: CodingKey?) throws -> T {
        guard let optional else {
            let context = DecodingError.Context(codingPath: [key].compactMap { $0 }, debugDescription: "Value wasn`t available.")
            throw DecodingError.valueNotFound(T.self, context)
        }

        return optional
    }
}

// MARK: CustomStringConvertible

extension Content: CustomStringConvertible {
    public var description: String {
        switch state {
        case .error(let error):
            return "Content(error: \(error)"
        case .node(let node):
            return createString(root: node)
        }
    }
    
    private func createString(root: State.Node?, tabs: String = "") -> String {
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
                string.append(stringVal.inQuotes)
            } else {
                string.append("\(value)".inQuotes)
            }
        case .dictionary(let dict):
            tabs += "\t"
            string.append("{\n")
            for (index, (key, node)) in dict.enumerated() {
                let comma = index == dict.count - 1 ? "" : ","
                string.append(tabs + "\(key.inQuotes): " + createString(root: node, tabs: tabs) + "\(comma)\n")
            }
            tabs = String(tabs.dropLast(1))
            string.append("\(tabs)}")
        case .null, .none:
            string.append("null")
        }
        
        return string
    }
}

// MARK: Encodable

extension Content: Encodable {
    public func encode(to encoder: Encoder) throws {
        switch state {
        case .error(let error):
            throw error
        case .node(let node):
            try node.encode(to: encoder)
        }
    }
}

extension Content.State.Node: Encodable {
    private struct GenericCodingKey: CodingKey {
        let stringValue: String
        let intValue: Int?

        init(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = Int(stringValue)
        }

        init(intValue: Int) {
            self.stringValue = "\(intValue)"
            self.intValue = intValue
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .array(let array):
            var container = encoder.unkeyedContainer()
            try container.encode(contentsOf: array)
        case .dictionary(let dict):
            var container = encoder.container(keyedBy: GenericCodingKey.self)
            for (key, value) in dict {
                let key = GenericCodingKey(stringValue: key)
                try container.encode(value, forKey: key)
            }
        case .value(let value):
            var container = encoder.singleValueContainer()
            if let bool = value.bool { try container.encode(bool) }
            if let string = value.string { try container.encode(string) }
            if let double = value.double { try container.encode(double) }
            if let int = value.int { try container.encode(int) }
            if let file = value.file { try container.encode(file.content?.data)}
        case .null:
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        }
    }
}

// MARK: Array Extensions

extension Array where Element == Content {
    public var string: [String]? { try? stringThrowing }
    public var stringThrowing: [String] { get throws { try map { try $0.stringThrowing } } }
    public var int: [Int]? { try? intThrowing }
    public var intThrowing: [Int] { get throws { try map { try $0.intThrowing } } }
    public var bool: [Bool]? { try? boolThrowing }
    public var boolThrowing: [Bool] { get throws { try map { try $0.boolThrowing } } }
    public var double: [Double]? { try? doubleThrowing }
    public var doubleThrowing: [Double] { get throws { try map { try $0.doubleThrowing } } }

    public subscript(field: String) -> [Content] {
        return map { $0[field] }
    }

    public subscript(dynamicMember member: String) -> [Content] {
        self[member]
    }

    public func decodeEach<D: Decodable>(_ type: D.Type = D.self) throws -> [D] {
        try map { try D(from: GenericDecoder(delegate: $0)) }
    }
}
