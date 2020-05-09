public protocol DatabaseEncodable: Encodable {}
public protocol DatabaseDecodable: Decodable {}

/// A type that can be encoded to & from a `Database`. Likely represents a table in a relational database.
public typealias DatabaseCodable = DatabaseEncodable & DatabaseDecodable
