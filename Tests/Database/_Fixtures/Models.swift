import Alchemy

@Model
struct SeedModel: Seedable {
    struct Migrate: Migration {
        func up(db: Database) async throws {
            try await db.createTable("seed_models") {
                $0.increments("id").primary()
                $0.string("name").notNull()
                $0.string("email").notNull().unique()
            }
        }
        
        func down(db: Database) async throws {
            try await db.dropTable("seed_models")
        }
    }
    
    var id: Int
    let name: String
    let email: String
    
    static func generate() -> SeedModel {
        SeedModel(name: faker.name.name(), email: faker.internet.email())
    }
}

@Model
struct OtherSeedModel: Seedable {
    struct Migrate: Migration {
        func up(db: Database) async throws {
            try await db.createTable("other_seed_models") {
                $0.uuid("id").primary()
                $0.int("foo").notNull()
                $0.bool("bar").notNull()
            }
        }
        
        func down(db: Database) async throws {
            try await db.dropTable("seed_models")
        }
    }
    
    var id: UUID = UUID()
    let foo: Int
    let bar: Bool
    
    static func generate() -> OtherSeedModel {
        OtherSeedModel(foo: faker.number.randomInt(), bar: .random())
    }
}
