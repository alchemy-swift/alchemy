import Collections

extension Model {

    // MARK: Dirty

    public var isDirty: Bool {
        (try? !dirtyFields().isEmpty) ?? false
    }

    public func isDirty(_ column: String) -> Bool {
        (try? dirtyFields()[column]) != nil
    }

    public func dirtyFields() throws -> SQLFields {
        let oldFields = row?.fields.filter { $0.value.sqlValue != .null }.mapValues(\.sql) ?? [:]
        let newFields = try fields().mapValues(\.sql)
        var dirtyFields = newFields.filter { $0.value != oldFields[$0.key] }
        for key in Set(oldFields.keys).subtracting(newFields.keys) {
            dirtyFields[key] = .null
        }
        
        return dirtyFields.mapValues { $0 }
    }

    // MARK: Clean

    public var isClean: Bool {
        !isDirty
    }

    public func isClean(_ column: String) -> Bool {
        !isDirty(column)
    }
}
