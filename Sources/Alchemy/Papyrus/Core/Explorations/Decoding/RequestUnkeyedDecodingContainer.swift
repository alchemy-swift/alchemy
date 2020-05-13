//struct RequestUnkeyedDecodingContainer: UnkeyedDecodingContainer {
//    var codingPath: [CodingKey]
//
//    var count: Int?
//
//    var isAtEnd: Bool
//
//    var currentIndex: Int
//
//    mutating func decodeNil() throws -> Bool {
//        <#code#>
//    }
//
//    mutating func decode(_ type: Bool.Type) throws -> Bool {
//        <#code#>
//    }
//
//    mutating func decode(_ type: String.Type) throws -> String {
//        <#code#>
//    }
//
//    mutating func decode(_ type: Double.Type) throws -> Double {
//        <#code#>
//    }
//
//    mutating func decode(_ type: Float.Type) throws -> Float {
//        <#code#>
//    }
//
//    mutating func decode(_ type: Int.Type) throws -> Int {
//        <#code#>
//    }
//
//    mutating func decode(_ type: Int8.Type) throws -> Int8 {
//        <#code#>
//    }
//
//    mutating func decode(_ type: Int16.Type) throws -> Int16 {
//        <#code#>
//    }
//
//    mutating func decode(_ type: Int32.Type) throws -> Int32 {
//        <#code#>
//    }
//
//    mutating func decode(_ type: Int64.Type) throws -> Int64 {
//        <#code#>
//    }
//
//    mutating func decode(_ type: UInt.Type) throws -> UInt {
//        <#code#>
//    }
//
//    mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
//        <#code#>
//    }
//
//    mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
//        <#code#>
//    }
//
//    mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
//        <#code#>
//    }
//
//    mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
//        <#code#>
//    }
//
//    mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
//        <#code#>
//    }
//
//    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
//        <#code#>
//    }
//
//    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
//        <#code#>
//    }
//
//    mutating func superDecoder() throws -> Decoder {
//        <#code#>
//    }
//}
