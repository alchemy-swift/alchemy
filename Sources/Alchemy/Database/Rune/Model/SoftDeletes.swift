public protocol SoftDeletes {
    static var deletedAtKey: String { get }
}

extension SoftDeletes {
    public static var deletedAtKey: String { "deletedAt" }
}

extension SoftDeletes where Self: Model {
    public var isDeleted: Bool {
        deletedAt != nil
    }

    public internal(set) var deletedAt: Date? {
        get { try? row?[Self.deletedAtKey]?.date() }
        nonmutating set {
            guard let row else { return }
            var dict = row.fieldDictionary
            dict[Self.deletedAtKey] = newValue.map { .date($0) } ?? .null
            self.row = SQLRow(dictionary: dict)
        }
    }
}

extension Model where Self: SoftDeletes {
    public static func query(on db: Database = database) -> Query<Self> {
        db.table(Self.self).withoutDeleted()
    }

    public static func withDeleted(on db: Database = database) -> Query<Self> {
        db.table(Self.self)
    }

    public static func onlyDeleted(on db: Database = database) -> Query<Self> {
        db.table(Self.self).onlyDeleted()
    }

    @discardableResult
    public func restore(on db: Database = database) async throws -> Self {
        try await update([Self.deletedAtKey: .null])
    }

    public func forceDelete(on db: Database = database) async throws {
        try await [self].forceDeleteAll(on: db)
    }
}

extension Array where Element: Model & SoftDeletes {
    public func restoreAll(on db: Database = Element.database) async throws {
        try await updateAll([Element.deletedAtKey: .null])
    }

    public func forceDeleteAll(on db: Database = Element.database) async throws {
        try await Element.willDelete(self)
        try await db.table(Element.self)
            .where("id", in: map(\.id))
            .forceDelete()
        try await Element.didDelete(self)
    }
}

extension Query where Result: SoftDeletes {
    public func withoutDeleted() -> Self {
        whereNull(Result.deletedAtKey)
    }

    public func onlyDeleted() -> Self {
        whereNotNull(Result.deletedAtKey)
    }

    public func restore() async throws {
        try await update([Result.deletedAtKey: .null])
    }

    public func forceDelete() async throws {
        guard let table else {
            throw DatabaseError("Table required to run query - use `.from(...)` to set one.")
        }

        let sql = db.grammar.delete(table, wheres: wheres)
        try await db.query(sql: sql, logging: logging)
    }
}
