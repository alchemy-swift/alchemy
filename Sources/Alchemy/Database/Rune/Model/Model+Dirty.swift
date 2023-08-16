extension Model {
    public var isDirty: Bool {
        !dirtyFields().isEmpty
    }

    public func isDirty<M: ModelProperty & Equatable>(_ keyPath: WritableKeyPath<Self, M>) -> Bool {
        guard let column = Self.column(for: keyPath) else {
            return false
        }

        return dirtyFields()[column] != nil
    }

    public func dirtyFields() -> [String: SQL] {
        guard let fields = try? fields() else {
            return [:]
        }

        let oldValues = row?.fieldDictionary.mapValues(\.sql) ?? [:]
        let newValues = fields.mapValues(\.sql)
        let newKeys = newValues.keys
        let removed = oldValues
            .filter { $0.value == SQL.null }
            .filter { !newKeys.contains($0.key) }
            .mapValues { _ in SQL.value(.null) }
        return newValues.filter { $0.value != oldValues[$0.key] } + removed
    }
}

extension ModelProperty where Self: Equatable {
    func compare(row: SQLRow, column: String) -> Bool {
        let reader = GenericRowReader(row: row, keyMapping: .snakeCase, jsonDecoder: JSONDecoder())
        let old = try! Self(key: column, on: reader)
        return self == old
    }
}
