import Foundation

public struct StoredProperty: Equatable {
    public static func == (lhs: StoredProperty, rhs: StoredProperty) -> Bool {
        lhs.key == rhs.key && lhs.type == rhs.type
    }
    
    public indirect enum PropertyType: Equatable {
        public static func == (lhs: StoredProperty.PropertyType, rhs: StoredProperty.PropertyType) -> Bool {
            if case .int = lhs, case .int = rhs {
                return true
            } else if case .double = lhs, case .double = rhs {
                return true
            } else if case .bool = lhs, case .bool = rhs {
                return true
            } else if case .string = lhs, case .string = rhs {
                return true
            } else if case .date = lhs, case .date = rhs {
                return true
            } else if case .json = lhs, case .json = rhs {
                return true
            } else if case .uuid = lhs, case .uuid = rhs {
                return true
            } else if case .array = lhs, case .array = rhs {
                return true
            } else {
                return false
            }
        }
        
        case int(Int)
        case double(Double)
        case bool(Bool)
        case string(String)
        case date(Date)
        case json(Data)
        case uuid(UUID)
        case array(PropertyType)
    }
    
    public let key: String
    public let type: PropertyType
}

extension Encodable {
    public func storedProperties() throws -> [StoredProperty] {
        try StoredPropertyReader()
            .readStoredProperties(of: self)
    }
}
