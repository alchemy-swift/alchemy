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

extension Faker {
    static let `default` = Faker()
}

extension Model {
    public static var faker: Faker { .default }
}
