import Collections

public protocol Seedable {
    static func generate() async throws -> Self
}

extension Seedable where Self: Model {
    public static func randomOrSeed() async throws -> Self {
        guard let random = try await random() else {
            return try await seed()
        }

        return random
    }

    @discardableResult
    public static func seed(on db: Database = DB,
                            fields: SQLFields = [:],
                            modifier: ((inout Self) async throws -> Void)? = nil) async throws -> Self {
        try await seed(on: db, 1, fields: fields, modifier: modifier).first!
    }

    @discardableResult
    public static func seed(
        on db: Database = DB,
        _ count: Int = 1,
        fields: SQLFields = [:],
        modifier: ((inout Self) async throws -> Void)? = nil
    ) async throws -> [Self] {
        var models: [Self] = []
        for _ in 1...count {
            var model = try await generate()
            try await modifier?(&model)
            models.append(model)
        }

        return try await models._insertReturnAll(on: db, fieldOverrides: fields)
    }
}
