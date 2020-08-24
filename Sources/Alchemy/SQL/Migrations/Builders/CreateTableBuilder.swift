import Foundation

extension Encodable {
    var sql: SQLJSON {
        SQLJSON(value: self)
    }
}
