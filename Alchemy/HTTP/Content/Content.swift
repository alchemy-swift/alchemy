/// Utility making it easy to set or modify HTTP content.
@dynamicMemberLookup
public final class Content: Buildable {
    public indirect enum Value:
        ExpressibleByNilLiteral,
        ExpressibleByBooleanLiteral,
        ExpressibleByIntegerLiteral,
        ExpressibleByFloatLiteral,
        ExpressibleByStringInterpolation,
        ExpressibleByArrayLiteral,
        ExpressibleByDictionaryLiteral
    {
        case string(String)
        case bool(Bool)
        case double(Double)
        case int(Int)
        case file(File)
        case dictionary([String: Value])
        case array([Value])
        case null

        public var string: String? {
            if case .string(let string) = self { return string }
            else { return nil }
        }

        public var bool: Bool? {
            if case .bool(let bool) = self { return bool }
            if case .string(let string) = self { return Bool(string) }
            if case .int(let int) = self { return int != 0 }
            else { return nil }
        }

        public var double: Double? {
            if case .double(let double) = self { return double }
            if case .string(let string) = self { return Double(string) }
            else { return nil }
        }

        public var int: Int? {
            if case .int(let int) = self { return int }
            if case .string(let string) = self { return Int(string) }
            else { return nil }
        }

        public var file: File? {
            if case .file(let file) = self { return file }
            else { return nil }
        }

        public var array: [Value]? {
            if case .array(let array) = self { return array }
            else { return nil }
        }

        public var dictionary: [String: Value]? {
            if case .dictionary(let dictionary) = self { return dictionary }
            else { return nil }
        }

        public init(nilLiteral: ()) {
            self = .null
        }

        public init(booleanLiteral bool: Bool) {
            self = .bool(bool)
        }

        public init(integerLiteral int: Int) {
            self = .int(int)
        }

        public init(floatLiteral double: Double) {
            self = .double(double)
        }

        public init(stringLiteral string: StringLiteralType) {
            self = .string(string)
        }

        public init(arrayLiteral elements: Value...) {
            self = .array(elements)
        }

        public init(dictionaryLiteral elements: (String, Value)...) {
            self = .dictionary(Dictionary(elements))
        }
    }

    public enum State {
        case value(Value)
        case error(ContentError)
    }

    public enum Operator: CustomStringConvertible {
        case field(String)
        case index(Int)
        case flatten

        public var description: String {
            switch self {
            case .field(let field): field
            case .index(let index): "\(index)"
            case .flatten: "*"
            }
        }
    }

    /// The state of this node; either an error or a value.
    public let state: State
    
    /// The path taken to get here.
    public let path: [Operator]

    public var string: String? { value?.string }
    public var stringThrowing: String { get throws { try unwrap(string) } }
    public var int: Int? { value?.int }
    public var intThrowing: Int { get throws { try unwrap(int) } }
    public var bool: Bool? { value?.bool }
    public var boolThrowing: Bool { get throws { try unwrap(bool) } }
    public var double: Double? { value?.double }
    public var doubleThrowing: Double { get throws { try unwrap(double) } }
    public var file: File? { value?.file }
    public var fileThrowing: File { get throws { try unwrap(file) } }
    public var array: [Content]? { value?.array?.enumerated().map { Content(value: $1, path: path + [.index($0)]) } }
    public var arrayThrowing: [Content] { get throws { try unwrap(array) } }
    public var dictionary: [String: Content]? {
        value?.dictionary?
            .map { (key: $0, value: Content(value: $1, path: path + [.field($0)])) }
            .keyed(by: \.key)
            .mapValues(\.value)
    }
    
    public var dictionaryThrowing: [String: Content] { get throws { try unwrap(dictionary) } }
    public var isNull: Bool {
        if case .null = value {
            return true
        } else {
            return value == nil
        }
    }

    public var error: ContentError? {
        guard case .error(let error) = state else { return nil }
        return error
    }

    public var value: Value? {
        guard case .value(let value) = state else { return nil }
        return value
    }

    public init(value: Value, path: [Operator] = []) {
        self.state = .value(value)
        self.path = path
    }
    
    public init(error: ContentError, path: [Operator] = []) {
        self.state = .error(error)
        self.path = path
    }

    public func decode<D: Decodable>(_ type: D.Type = D.self) throws -> D {
        do {
            return try D(from: GenericDecoder(delegate: self))
        } catch {
            if path.isEmpty {
                throw ValidationError("Unable to decode \(D.self) from body.")
            } else {
                let pathString = path.map(\.description).joined(separator: ".")
                throw ValidationError("Unable to decode \(D.self) from field \(pathString).")
            }
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
        case .value(let value):
            guard case .array(let array) = value else {
                return Content(error: ContentError.notArray, path: newPath)
            }
            
            return Content(value: array[index], path: newPath)
        case .error(let error):
            return Content(error: error, path: newPath)
        }
    }
    
    public subscript(field: String) -> Content {
        let newPath = path + [.field(field)]
        switch state {
        case .value(let value):
            guard case .dictionary(let dict) = value else {
                return Content(error: ContentError.notDictionary, path: newPath)
            }
            
            return Content(value: dict[field] ?? .null, path: newPath)
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
        case .value(let value):
            switch value {
            case .dictionary(let dict):
                return Array(dict.values).map { Content(value: $0, path: newPath) }
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
                    .map { Content(value: $0, path: newPath) }
            default:
                return [Content(error: ContentError.cantFlatten, path: newPath)]
            }
        case .error(let error):
            return [Content(error: error, path: newPath)]
        }
    }

    // MARK: Operators

    public static func * (lhs: Content, rhs: Content) {}

    public static func == (lhs: Content, rhs: Void?) -> Bool {
        switch lhs.state {
        case .value(let value):
            guard case .null = value else {
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
        guard 
            case .value(let value) = state,
            case .dictionary(let dict) = value
        else { return [] }
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
        guard case .value(let value) = state, case .dictionary(let dict) = value else {
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
            return "Error: \(error)"
        case .value(let value):
            return createDescription(root: value)
        }
    }
    
    private func createDescription(root: Value, tabs: String = "") -> String {
        var desc = ""
        var tabs = tabs
        switch root {
        case .array(let array):
            tabs += "\t"
            if array.isEmpty {
                desc.append("[]")
            } else {
                desc.append("[\n")
                for (index, value) in array.enumerated() {
                    let comma = index == array.count - 1 ? "" : ","
                    desc.append(tabs + createDescription(root: value, tabs: tabs) + "\(comma)\n")
                }
                tabs = String(tabs.dropLast(1))
                desc.append("\(tabs)]")
            }
        case .string(let string):
            desc.append(string)
        case .bool(let bool):
            desc.append("\(bool)")
        case .int(let int):
            desc.append("\(int)")
        case .double(let double):
            desc.append("\(double)")
        case .file(let file):
            desc.append("<\(file.name)>")
        case .dictionary(let dict):
            tabs += "\t"
            desc.append("{\n")
            for (index, (key, value)) in dict.enumerated() {
                let comma = index == dict.count - 1 ? "" : ","
                desc.append(tabs + "\(key.inQuotes): " + createDescription(root: value, tabs: tabs) + "\(comma)\n")
            }
            tabs = String(tabs.dropLast(1))
            desc.append("\(tabs)}")
        case .null:
            desc.append("null")
        }
        
        return desc
    }
}

// MARK: Codable

extension Content: Encodable {
    public func encode(to encoder: Encoder) throws {
        switch state {
        case .error(let error):
            throw error
        case .value(let value):
            try value.encode(to: encoder)
        }
    }
}

extension Content.Value: Encodable {
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
        case .string(let string):
            var container = encoder.singleValueContainer()
            try container.encode(string)
        case .bool(let bool):
            var container = encoder.singleValueContainer()
            try container.encode(bool)
        case .int(let int):
            var container = encoder.singleValueContainer()
            try container.encode(int)
        case .double(let double):
            var container = encoder.singleValueContainer()
            try container.encode(double)
        case .file(let file):
            var container = encoder.singleValueContainer()
            try container.encode(file.content?.data)
        case .null:
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        }
    }
}

extension Content.Value: ModelProperty {
    public init(key: String, on row: SQLRowReader) throws {
        throw ContentError.notSupported("Reading content from database models isn't supported, yet.")
    }
    
    public func store(key: String, on row: inout SQLRowWriter) throws {
        switch self {
        case .array(let values):
            try row.put(json: values, at: key)
        case .dictionary(let dict):
            try row.put(json: dict, at: key)
        case .bool(let value):
            try value.store(key: key, on: &row)
        case .string(let value):
            try value.store(key: key, on: &row)
        case .int(let value):
            try value.store(key: key, on: &row)
        case .double(let double):
            try double.store(key: key, on: &row)
        case .file(let file):
            if let buffer = file.content?.buffer {
                row.put(SQLValue.bytes(buffer), at: key)
            } else {
                row.put(SQLValue.null, at: key)
            }
        case .null:
            row.put(SQLValue.null, at: key)
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
