import Fakery

public protocol Seeder {
    func run() async throws
}

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
    public static func seed(_ modifier: ((inout Self) async throws -> Void)? = nil) async throws -> Self {
        try await _seed(1, modifier: modifier).first!
    }

    @discardableResult
    public static func seed(_ fieldOverrides: [String: SQLConvertible]) async throws -> Self {
        try await _seed(1, fieldOverrides: fieldOverrides).first!
    }

    @discardableResult
    public static func seed(_ count: Int, _ modifier: ((inout Self) async throws -> Void)? = nil) async throws -> [Self] {
        try await _seed(count, modifier: modifier)
    }

    @discardableResult
    public static func seed(_ count: Int, _ fieldOverrides: [String: SQLConvertible] = [:]) async throws -> [Self] {
        try await _seed(count, fieldOverrides: fieldOverrides)
    }

    @discardableResult
    private static func _seed(_ count: Int, 
                              modifier: ((inout Self) async throws -> Void)? = nil,
                              fieldOverrides: [String: SQLConvertible] = [:]
    ) async throws -> [Self] {
        var models: [Self] = []
        for _ in 1...count {
            var model = try await generate()
            try await modifier?(&model)
            models.append(model)
        }

        return try await models._insertReturnAll(fieldOverrides: fieldOverrides)
    }
}

extension Database {
    /// Seeds the database by running each seeder in `seeders`
    /// consecutively.
    public func seed() async throws {
        for seeder in seeders {
            try await seeder.run()
        }
    }

    public func seed(with seeder: Seeder) async throws {
        try await seeder.run()
    }

    func seed(names seederNames: [String]) async throws {
        let toRun = try seederNames.map { name in
            guard let match = seeders.first(where: {
                $0.name.lowercased() == name.lowercased() ||
                $0.name.lowercased().droppingSuffix("seeder") == name.lowercased()
            }) else {
                throw DatabaseError("Unable to find a seeder on this database named \(name) or \(name)Seeder.")
            }

            return match
        }

        for seeder in toRun {
            try await seeder.run()
        }
    }
}

extension Seeder {
    fileprivate var name: String {
        Alchemy.name(of: Self.self)
    }
}

extension Model {
    public static var faker: Faker { Faker() }
}
