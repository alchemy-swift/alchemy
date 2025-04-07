@testable
import Alchemy
import AlchemyTesting
import Foundation

struct MakeCommandTests {
    let fileName: String = UUID().uuidString

    init() {
        FileCreator.mock()
    }

    @Test func columnData() throws {
        #expect(throws: Error.self) { try ColumnData(from: "foo") }
        #expect(throws: Error.self) { try ColumnData(from: "foo:bar") }
        #expect(try ColumnData(from: "foo:string:primary") == ColumnData(name: "foo", type: "string", modifiers: ["primary"]))
        #expect(try ColumnData(from: "foo:bigint") == ColumnData(name: "foo", type: "bigInt", modifiers: []))
    }

    @Test func makeController() throws {
        try ControllerMakeCommand(name: fileName).run()
        #expect(FileCreator.shared.fileExists(at: "Controllers/\(fileName).swift"))

        try ControllerMakeCommand(model: fileName).run()
        #expect(FileCreator.shared.fileExists(at: "Controllers/\(fileName)Controller.swift"))
    }

    @Test func makeJob() throws {
        try JobMakeCommand(name: fileName).run()
        #expect(FileCreator.shared.fileExists(at: "Jobs/\(fileName).swift"))
    }

    @Test func makeMiddleware() throws {
        try MiddlewareMakeCommand(name: fileName).run()
        #expect(FileCreator.shared.fileExists(at: "Middleware/\(fileName).swift"))
    }

    @Test func makeMigration() throws {
        try MigrationMakeCommand(name: fileName, table: "users", columns: .testData).run()
        #expect(FileCreator.shared.fileExists(at: "Database/Migrations/\(fileName).swift"))
        #expect(throws: Error.self) { try MigrationMakeCommand(name: fileName + ":", table: "users", columns: .testData).run() }
    }

    @Test func makeModel() throws {
        try ModelMakeCommand(name: fileName, columns: .testData, migration: true, controller: true).run()
        #expect(FileCreator.shared.fileExists(at: "Models/\(fileName).swift"))
        #expect(FileCreator.shared.fileExists(at: "Database/Migrations/Create\(fileName)s.swift"))
        #expect(FileCreator.shared.fileExists(at: "Controllers/\(fileName)Controller.swift"))
        #expect(throws: Error.self) { try ModelMakeCommand(name: fileName + ":").run() }
    }

    @Test func makeView() throws {
        try ViewMakeCommand(name: fileName).run()
        #expect(FileCreator.shared.fileExists(at: "Views/\(fileName).swift"))
    }
}


extension Array where Element == ColumnData {
    static let testData: [ColumnData] = [
        ColumnData(name: "id", type: "increments", modifiers: ["primary"]),
        ColumnData(name: "email", type: "string", modifiers: ["notNull", "unique"]),
        ColumnData(name: "password", type: "string", modifiers: ["notNull"]),
        ColumnData(name: "parent_id", type: "bigint", modifiers: ["references.users.id"]),
        ColumnData(name: "uuid", type: "uuid", modifiers: ["notNull"]),
        ColumnData(name: "double", type: "double", modifiers: ["notNull"]),
        ColumnData(name: "bool", type: "bool", modifiers: ["notNull"]),
        ColumnData(name: "date", type: "date", modifiers: ["notNull"]),
        ColumnData(name: "json", type: "json", modifiers: ["notNull"]),
    ]
}
