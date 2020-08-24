import Foundation

public final class CreateTableBuilder: ColumnCreator, IndexCreator {
    var createIndexes: [CreateIndex] = []
}

extension Encodable {
    var sql: SQLJSON {
        SQLJSON(value: self)
    }
}
