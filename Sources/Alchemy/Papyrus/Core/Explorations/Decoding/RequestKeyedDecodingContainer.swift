//struct RequestKeyedDecodingContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
//    typealias Key = K
//    
//    var codingPath: [CodingKey]
//
//    var allKeys: [K]
//
//    func contains(_ key: K) -> Bool {
//        <#code#>
//    }
//
//    func decodeNil(forKey key: K) throws -> Bool {
//        <#code#>
//    }
//
//    func decode(_ type: Bool.Type, forKey key: K) throws -> Bool {
//        <#code#>
//    }
//
//    func decode(_ type: String.Type, forKey key: K) throws -> String {
//        <#code#>
//    }
//
//    func decode(_ type: Double.Type, forKey key: K) throws -> Double {
//        <#code#>
//    }
//
//    func decode(_ type: Float.Type, forKey key: K) throws -> Float {
//        <#code#>
//    }
//
//    func decode(_ type: Int.Type, forKey key: K) throws -> Int {
//        <#code#>
//    }
//
//    func decode(_ type: Int8.Type, forKey key: K) throws -> Int8 {
//        <#code#>
//    }
//
//    func decode(_ type: Int16.Type, forKey key: K) throws -> Int16 {
//        <#code#>
//    }
//
//    func decode(_ type: Int32.Type, forKey key: K) throws -> Int32 {
//        <#code#>
//    }
//
//    func decode(_ type: Int64.Type, forKey key: K) throws -> Int64 {
//        <#code#>
//    }
//
//    func decode(_ type: UInt.Type, forKey key: K) throws -> UInt {
//        <#code#>
//    }
//
//    func decode(_ type: UInt8.Type, forKey key: K) throws -> UInt8 {
//        <#code#>
//    }
//
//    func decode(_ type: UInt16.Type, forKey key: K) throws -> UInt16 {
//        <#code#>
//    }
//
//    func decode(_ type: UInt32.Type, forKey key: K) throws -> UInt32 {
//        <#code#>
//    }
//
//    func decode(_ type: UInt64.Type, forKey key: K) throws -> UInt64 {
//        <#code#>
//    }
//
//    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T : Decodable {
//        <#code#>
//    }
//
//    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
//        <#code#>
//    }
//
//    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
//        <#code#>
//    }
//
//    func superDecoder() throws -> Decoder {
//        <#code#>
//    }
//
//    func superDecoder(forKey key: K) throws -> Decoder {
//        <#code#>
//    }
//}
