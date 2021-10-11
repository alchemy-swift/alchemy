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
        
        return try await rows.insertAll()
    }
}

extension Faker {
    static let `default` = Faker()
}

extension Model {
    public static func random() async throws -> Self? {
        try await Self.query().select().orderBy(column: "RANDOM()").limit(1).firstModel()
    }
    
    public static var faker: Faker { .default }
}
