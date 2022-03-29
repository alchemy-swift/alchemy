public protocol Timestamps {
    static var createdAtKey: String { get }
    static var updatedAtKey: String { get }
}

extension Timestamps {
    public static var createdAtKey: String { "createdAt" }
    public static var updatedAtKey: String { "updatedAt" }
}

struct TimestampModifier {
    func willCreate<M: Model>(row: inout SQLRowWriter, type: M.Type) {
        if let type = type as? Timestamps.Type {
            row[type.createdAtKey] = .now
            row[type.updatedAtKey] = .now
        }
    }
    
    func willUpdate<M: Model>(row: inout SQLRowWriter, type: M.Type) {
        if let type = type as? Timestamps.Type {
            row[type.updatedAtKey] = .now
        }
    }
}
