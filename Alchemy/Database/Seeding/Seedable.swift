import Collections
import Fakery

public protocol Seedable {
    static func generate() async throws -> Self
}

extension Seedable where Self: Model {
    public static var faker: Faker {
        Faker()
    }

    public static func randomOrSeed() async throws -> Self {
        guard let random = try await random() else {
            return try await seed()
        }

        return random
    }

    @discardableResult
    public static func seed(fields: SQLFields = [:], modifier: ((inout Self) async throws -> Void)? = nil) async throws -> Self {
        try await seed(1, fields: fields, modifier: modifier).first!
    }

    @discardableResult
    public static func seed(
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

        return try await models._insertReturnAll(fieldOverrides: fields)
    }
}
