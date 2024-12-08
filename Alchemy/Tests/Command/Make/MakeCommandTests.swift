@testable
import Alchemy
import AlchemyTesting

final class MakeCommandTests: TestCase<TestApp> {
    var fileName: String = UUID().uuidString
    
    override func setUp() {
        super.setUp()
        fileName = UUID().uuidString
        FileCreator.mock()
    }
    
    func testColumnData() {
        XCTAssertThrowsError(try ColumnData(from: "foo"))
        XCTAssertThrowsError(try ColumnData(from: "foo:bar"))
        XCTAssertEqual(try ColumnData(from: "foo:string:primary"), ColumnData(name: "foo", type: "string", modifiers: ["primary"]))
        XCTAssertEqual(try ColumnData(from: "foo:bigint"), ColumnData(name: "foo", type: "bigInt", modifiers: []))
    }
    
    func testMakeController() throws {
        try ControllerMakeCommand(name: fileName).run()
        XCTAssertTrue(FileCreator.shared.fileExists(at: "Controllers/\(fileName).swift"))
        
        try ControllerMakeCommand(model: fileName).run()
        XCTAssertTrue(FileCreator.shared.fileExists(at: "Controllers/\(fileName)Controller.swift"))
    }
    
    func testMakeJob() throws {
        try JobMakeCommand(name: fileName).run()
        XCTAssertTrue(FileCreator.shared.fileExists(at: "Jobs/\(fileName).swift"))
    }
    
    func testMakeMiddleware() throws {
        try MiddlewareMakeCommand(name: fileName).run()
        XCTAssertTrue(FileCreator.shared.fileExists(at: "Middleware/\(fileName).swift"))
    }
    
    func testMakeMigration() throws {
        try MigrationMakeCommand(name: fileName, table: "users", columns: .testData).run()
        XCTAssertTrue(FileCreator.shared.fileExists(at: "Database/Migrations/\(fileName).swift"))
        XCTAssertThrowsError(try MigrationMakeCommand(name: fileName + ":", table: "users", columns: .testData).run())
    }
    
    func testMakeModel() throws {
        try ModelMakeCommand(name: fileName, columns: .testData, migration: true, controller: true).run()
        XCTAssertTrue(FileCreator.shared.fileExists(at: "Models/\(fileName).swift"))
        XCTAssertTrue(FileCreator.shared.fileExists(at: "Database/Migrations/Create\(fileName)s.swift"))
        XCTAssertTrue(FileCreator.shared.fileExists(at: "Controllers/\(fileName)Controller.swift"))
        XCTAssertThrowsError(try ModelMakeCommand(name: fileName + ":").run())
    }
    
    func testMakeView() throws {
        try ViewMakeCommand(name: fileName).run()
        XCTAssertTrue(FileCreator.shared.fileExists(at: "Views/\(fileName).swift"))
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
