@testable
import Alchemy
import AlchemyTesting

struct SeederTests: AppSuite {
    let app = TestApp()

    @Test func seedable() async throws {
        try await withApp { _ in
            try await DB.fake(migrations: [SeedModel.Migrate()])

            try await SeedModel.seed()
            #expect(try await SeedModel.all().count == 1)

            try await SeedModel.seed(10)
            #expect(try await SeedModel.all().count == 11)
        }
    }

    @Test func seeder() async throws {
        try await withApp { _ in
            try await DB.fake(
                migrations: [
                    SeedModel.Migrate(),
                    OtherSeedModel.Migrate()
                ],
                seeders: [TestSeeder()]
            )

            #expect(try await SeedModel.all().count == 10)
            #expect(try await OtherSeedModel.all().count == 0)

            try await DB.seed(with: OtherSeeder())
            #expect(try await OtherSeedModel.all().count == 11)
        }
    }

    @Test func seedWithNames() async throws {
        try await withApp { _ in
            try await DB.fake(
                migrations: [
                    SeedModel.Migrate(),
                    OtherSeedModel.Migrate()
                ]
            )

            DB.seeders = [
                TestSeeder(),
                OtherSeeder()
            ]

            try await DB.seed(names: ["otherseeder"])
            #expect(try await SeedModel.all().count == 0)
            #expect(try await OtherSeedModel.all().count == 11)

            await #expect(throws: Error.self) { try await DB.seed(names: ["foo"]) }
        }
    }
}


private struct TestSeeder: Seeder {
    func run() async throws {
        try await SeedModel.seed(10)
    }
}

private struct OtherSeeder: Seeder {
    func run() async throws {
        try await OtherSeedModel.seed(11)
    }
}
