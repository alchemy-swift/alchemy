import Foundation

public protocol Uniqueable {
    static func unique(id: Int) -> Self
}

extension String: Uniqueable {
    public static func unique(id: Int) -> String {
        UUID().uuidString
    }
}

extension Double: Uniqueable {
    public static func unique(id: Int) -> Double {
        Double(id)
    }
}

extension Float: Uniqueable {
    public static func unique(id: Int) -> Float {
        Float(id)
    }
}

extension Int: Uniqueable {}
extension Int8: Uniqueable {}
extension Int16: Uniqueable {}
extension Int32: Uniqueable {}
extension Int64: Uniqueable {}
extension UInt: Uniqueable {}
extension UInt8: Uniqueable {}
extension UInt16: Uniqueable {}
extension UInt32: Uniqueable {}
extension UInt64: Uniqueable {}

extension FixedWidthInteger {
    public static func unique(id: Int) -> Self {
        Self(id)
    }
}

extension Bool: Uniqueable {
    public static func unique(id: Int) -> Bool {
        id % 2 == 1
    }
}

extension CaseIterable {
    public static func unique(id: Int) -> Self {
        let index = id % allCases.count
        return allCases.enumerated().first(where: { i, _ in i == index })!.element
    }
}

extension Array: Uniqueable where Element: Uniqueable {
    public static func unique(id: Int) -> Self {
        [Element.unique(id: id)]
    }
}

extension Data: Uniqueable {
    public static func unique(id: Int) -> Data {
        Data([UInt8(id)])
    }
}
