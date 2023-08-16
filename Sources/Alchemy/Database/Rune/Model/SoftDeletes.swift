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
    public static func query(on db: Database) -> Query<Self> {
        db.table(Self.self).withoutDeleted()
    }

    public static func withDeleted(on db: Database) -> Query<Self> {
        db.table(Self.self)
    }

    public static func onlyDeleted(on db: Database) -> Query<Self> {
        db.table(Self.self).onlyDeleted()
    }
}

extension Query where Result: SoftDeletes {
    public func withoutDeleted() -> Self {
        whereNull(Result.deletedAtKey)
    }

    public func onlyDeleted() -> Self {
        whereNotNull(Result.deletedAtKey)
    }
}
