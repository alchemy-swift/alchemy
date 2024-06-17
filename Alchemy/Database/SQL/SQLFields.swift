import Collections

public typealias SQLFields = OrderedDictionary<String, SQLConvertible>

extension SQLFields {
    public static func + (lhs: SQLFields, rhs: SQLFields) -> SQLFields {
        lhs.merging(rhs, uniquingKeysWith: { _, b in b })
    }
}
