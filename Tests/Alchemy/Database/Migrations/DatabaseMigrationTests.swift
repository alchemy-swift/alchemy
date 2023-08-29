//@testable
//import Alchemy
//import AlchemyTest
//
//final class DatabaseMigrationTests: TestCase<TestApp> {
//    func testMigration() async throws {
//        let db = try await Database.fake()
//        try await db.rollbackMigrations()
//        db.migrations = [MigrationA()]
//        try await db.migrate()
//        AssertEqual(try await MigrationModel.all().count, 1)
//        db.migrations.append(MigrationB())
//        try await db.migrate()
//        AssertEqual(try await MigrationModel.all().count, 2)
//        try await db.rollbackMigrations()
//        AssertEqual(try await MigrationModel.all().count, 1)
//    }
//}
//
//private struct MigrationA: Migration {
//    func up(schema: Schema) {}
//    func down(schema: Schema) {}
//}
//
//private struct MigrationB: Migration {
//    func up(schema: Schema) {}
//    func down(schema: Schema) {}
//}
