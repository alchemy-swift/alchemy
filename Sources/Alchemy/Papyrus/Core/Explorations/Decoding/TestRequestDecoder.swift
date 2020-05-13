//protocol RequestDecoder: Decoder {}
//
///// https://github.com/ShawnMoore/XMLParsing/tree/master/Sources/XMLParsing/Decoder
//struct TestDecoder: RequestDecoder {
//    var codingPath: [CodingKey] = []
//
//    var userInfo: [CodingUserInfoKey : Any] = [ : ]
//
//    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
//        RequestKeyedDecodingContainer(codingPath: self.codingPath, allKeys: <#[K]#>)
//    }
//
//    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
//        RequestUnkeyedDecodingContainer(codingPath: self.codingPath, isAtEnd: <#Bool#>)
//    }
//
//    func singleValueContainer() throws -> SingleValueDecodingContainer {
//        RequestSingleValueDecodingContainer(codingPath: self.codingPath)
//    }
//}
