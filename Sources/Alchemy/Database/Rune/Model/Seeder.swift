import Fakery

public protocol Seeder {
    func run() async throws
}

public protocol Seedable {
    static func generate() async throws -> Self
}

extension Seedable where Self: Model {
    @discardableResult
    public static func seed() async throws -> Self {
        try await generate().save()
    }
    
    @discardableResult
    public static func seed(_ count: Int) async throws -> [Self] {
        var rows: [Self] = []
        for _ in 1...count {
            rows.append(try await generate())
        }
        
        return try await rows.insertReturnAll()
    }
    
    public static func randomOrSeed() async throws -> Self {
        guard let random = try await random() else {
            return try await seed()
        }
        
        return random
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
            return try seeders
                .first(where: {
                    $0.name.lowercased() == name.lowercased() ||
                    $0.name.lowercased().droppingSuffix("seeder") == name.lowercased()
                })
                .unwrap(or: DatabaseError("Unable to find a seeder on this database named \(name) or \(name)Seeder."))
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
