import Foundation
import EchoMirror
import EchoProperties

struct SomeStruct: Codable {
    let immutableString: String = "Josh"
    var data: Data = Data()
    var string: String = "Sir"
    var uuid: UUID = UUID()
    var url: URL = URL(string: "https://www.postgresql.org/docs/9.5/datatype.html")!
    var int: Int = 26
    var int8: Int8 = 2
    var int32: Int32 = 4
    var int64: Int64 = 8
    var double: Double = 26.0
    var date: Date = Date()
    var bool: Bool = false
    var optional: String? = nil
    var json: SomeJSON = SomeJSON(value: "someValue", other: 5)
    var array: [String] = ["first", "second", "third"]
}

struct SomeJSON: Codable {
    let value: String
    let other: Int
}

public struct CodableTester {
    public init() {}
    
    public func run() {
        let obj = SomeStruct()
        
        // Get mapping of `CodingKey` to it's value
        do {
            try self.usingCustomEncoder(obj)
        } catch {
            print("Error using dict: \(error)")
        }
        
        do {
            print(try (\SomeStruct.immutableString).name())
            print(try (\SomeStruct.date).name())
        } catch {
            print("Error getting kp name: \(error)")
        }
    }
    
    func usingCustomEncoder<E: Encodable>(_ obj: E) throws {
        let encoder = DatabaseEncoder()
        _ = try encoder.encode(obj, dateEncodingStrategy: .iso8601)
    }
}

struct DatabaseEncodingError: Error {
    let message: String
}
