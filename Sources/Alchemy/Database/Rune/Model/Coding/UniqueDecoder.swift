import Foundation

enum KeyPathCodingError: Error {
    case notFound
    case typeNotUnique
    case tooDeep
    case recursivePropertyDetected(String)
}

extension Decodable {
    /// Note - computed key paths such as `Array.count` shouldn't be used and
    /// have undefined behavior.
    static func string<T: Equatable>(for keyPath: KeyPath<Self, T>) throws -> String {
        try keys(for: keyPath)
            .map(\.stringValue)
            .joined(separator: ".")
    }

    private static func keys<T: Equatable>(for keyPath: KeyPath<Self, T>, onlyConsidering: [[CodingKey]]? = nil) throws -> [CodingKey] {
        let generator = UniqueGenerator(onlyConsidering: onlyConsidering)
        let instance = try Self(from: UniqueDecoder(codingPath: [], generator: generator))
        let uniqueValue = instance[keyPath: keyPath]
        let paths = generator.keys(for: uniqueValue)

        if let onlyConsidering = onlyConsidering {
            guard paths.count < onlyConsidering.count else {
                throw KeyPathCodingError.typeNotUnique
            }
        }

        if paths.isEmpty {
            throw KeyPathCodingError.notFound
        } else if paths.count == 1 {
            return paths[0]
        } else {
            return try keys(for: keyPath, onlyConsidering: paths)
        }
    }
}

private final class UniqueGenerator {
    let onlyConsidering: [[CodingKey]]?

    init(onlyConsidering: [[CodingKey]]? = nil) {
        self.onlyConsidering = onlyConsidering
    }

    var properties: [String: [(Any, [CodingKey])]] = [:]
    var count: [String: Int] = [:]

    func keys<T: Equatable>(for value: T) -> [[CodingKey]] {
        guard let typeValues = properties["\(T.self)"] else {
            return []
        }

        return typeValues.filter({ ($0.0 as! T) == value }).map(\.1)
    }

    func set<T>(_ type: T.Type, value: Any, keys: [CodingKey]) {
        if let onlyConsidering = onlyConsidering {
            guard onlyConsidering.contains(where: { $0.map(\.stringValue) == keys.map(\.stringValue) }) else {
                return
            }
        }

        properties["\(T.self)"] = (properties["\(T.self)"] ?? []) + [(value, keys)]
        count["\(type)"] = (count["\(type)"] ?? 0) + 1
    }
}

private struct UniqueDecoder: Decoder {
    let codingPath: [CodingKey]
    let generator: UniqueGenerator
    let userInfo: [CodingUserInfoKey : Any] = [:]
    var depth: Int = 0
    var nonUniquePath: [String] = []

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        try assertDepth()
        return KeyedDecodingContainer(Keyed(codingPath: codingPath, generator: generator, depth: depth, nonUniquePath: nonUniquePath))
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        try assertDepth()
        if !codingPath.isEmpty {
            return Unkeyed(codingPath: codingPath, generator: generator, depth: depth)
        } else {
            throw RuneError("Top level unkeyed containers aren't supported yet.")
        }
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        try assertDepth()
        return Single(codingPath: codingPath, generator: generator, depth: depth)
    }

    private func assertDepth() throws {
        guard depth <= 5 else {
            throw KeyPathCodingError.tooDeep
        }
    }
}

private struct Single: SingleValueDecodingContainer {
    var codingPath: [CodingKey] = []
    let generator: UniqueGenerator
    var depth: Int = 0

    func decodeNil() -> Bool {
        false
    }

    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        if let _type = type as? Uniqueable.Type {
            let number = generator.count["\(type)"] ?? 0
            let value = _type.unique(id: number + 1)
            generator.set(type, value: value, keys: codingPath)
            return value as! T
        } else {
            throw RuneError("Can't decode single at \(codingPath.map(\.stringValue).joined(separator: ".")) \(type).")
        }
    }
}

private final class Keyed<Key: CodingKey>: KeyedDecodingContainerProtocol {
    var codingPath: [CodingKey]
    var generator: UniqueGenerator
    var allKeys: [Key] = []
    var depth: Int = 0
    let nonUniquePath: [String]

    init(codingPath: [CodingKey], generator: UniqueGenerator, depth: Int, nonUniquePath: [String]) {
        self.codingPath = codingPath
        self.generator = generator
        self.depth = depth
        self.nonUniquePath = nonUniquePath
    }

    func contains(_ key: Key) -> Bool {
        true
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        false
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        if let _type = type as? Uniqueable.Type {
            let number = generator.count["\(type)"] ?? 0
            let value = _type.unique(id: number + 1)
            generator.set(type, value: value, keys: codingPath + [key])
            return value as! T
        }

        let typeString = "\(T.self)"
        if nonUniquePath.contains(typeString) {
            throw KeyPathCodingError.recursivePropertyDetected(typeString)
        }

        var path = nonUniquePath
        path.append("\(T.self)")
        let value = try T(from: UniqueDecoder(codingPath: codingPath + [key], generator: generator, depth: depth + 1, nonUniquePath: path))
        generator.set(type, value: value, keys: codingPath + [key])
        return value
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        throw RuneError("`DummyDecoder` doesn't support nested keyed containers yet.")
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        throw RuneError("`DummyDecoder` doesn't support nested unkeyed containers yet.")
    }

    func superDecoder() throws -> Decoder {
        throw RuneError("`DummyDecoder` doesn't support super decoding yet.")
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        throw RuneError("`DummyDecoder` doesn't support super decoding yet.")
    }
}

private struct Unkeyed: UnkeyedDecodingContainer {
    var codingPath: [CodingKey] = []
    let generator: UniqueGenerator
    var count: Int? { 1 }
    var isAtEnd: Bool { currentIndex == count }
    var currentIndex: Int = 0
    var depth: Int = 0

    mutating func decodeNil() throws -> Bool {
        false
    }

    mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        currentIndex += 1
        return try T(from: UniqueDecoder(codingPath: codingPath, generator: generator, depth: depth + 1))
    }

    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        throw RuneError("`DummyDecoder` doesn't support nested keyed containers yet.")
    }

    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        throw RuneError("`DummyDecoder` doesn't support nested unkeyed containers yet.")
    }

    mutating func superDecoder() throws -> Decoder {
        throw RuneError("`DummyDecoder` doesn't support super decoding yet.")
    }
}
