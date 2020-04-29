/// Can we form an SQL query string through a function chain that only accepts a `KeyPath` representing the
/// database field to work with. Both the `Root` and `Value` of the `KeyPath` are guaranteed to be `Codable`.

/// use: https://github.com/vapor/codable-kit

import Foundation

struct Teacher: Table {
    var firstName: String
//    var officeNumber: Int
//    var officeBuilding: OfficeBuilding
    var favoriteStudent: Student
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        print("Values are: \(values.allKeys) \(CodingKeys.firstName)")
        fatalError()
    }
}

extension String: TableColumn {}

struct Student: Table, TableColumn {
    var firstName: String
    var lastName: String
}

enum OfficeBuilding: String, Codable {
    case library
    case manchesterHall
    case studentRecCenter
}

protocol KeyPathListable {
    var _keyPathReadableFormat: [String: Any] { get }
    static var allKeyPaths: [KeyPath<Self, Any?>] { get }
}

extension KeyPathListable {
    var _keyPathReadableFormat: [String: Any] {
        let mirror = Mirror(reflecting: self)
        var description: [String: Any] = [:]
        for case let (label?, value) in mirror.children {
            description[label] = value
        }
        return description
    }

    static func allKeyPaths(of instance: Self) -> [KeyPath<Self, Any?>] {
        var keyPaths: [KeyPath<Self, Any?>] = []
        for (key, _) in instance._keyPathReadableFormat {
            keyPaths.append(\Self._keyPathReadableFormat[key])
        }
        return keyPaths
    }
}

public protocol Table: Codable {
    static var tableName: String { get }
}

extension Table {
    public static var tableName: String { String(describing: Self.self) }
}

public protocol TableColumn {
    
}

protocol Migration {
    associatedtype Model: Table
    static var tableName: String { get }
}

extension Table {
    
}

struct CreateTeacher: Migration {
    typealias Model = Teacher
    
    static let tableName: String = "teacher"
}

struct CreateStudent: Migration {
    typealias Model = Student
    
    static let tableName: String = "student"
}

extension Migration {
    /// Map keypaths to strings
    func add<Column: TableColumn>(keyPath: KeyPath<Model, Column>, columnName: String) {
        ModelLookup.shared.add(table: Model.self, keyPath: keyPath, columnName: columnName)
    }
    
    func getColumn<Column: TableColumn>(for keypath: KeyPath<Model, Column>) -> String? {
        ""
    }
}

class ModelLookup {
    static let shared = ModelLookup()
    
    // This will break if the app accesses multiple databases with the same table names.
    var models: [String: KeyPathCache] = [:]
    
    func add<T: Table>(table: T.Type, keyPath: PartialKeyPath<T>, columnName: String) {
        let tableName = table.tableName
        if let cache = self.models[tableName] {
            cache.keypaths[keyPath] = columnName
        } else {
            let cache = KeyPathCache()
            cache.keypaths[keyPath] = columnName
            self.models[tableName] = cache
        }
    }
    
    func printAll() {
        for (key, value) in self.models {
            print("----- Table '\(key)' -----")
            for (keyPath, columnName) in value.keypaths {
                print("-> '\(columnName)' \(keyPath)")
            }
            print("----- ----- ----- ----- -----")
        }
    }
}

class KeyPathCache {
    var keypaths: [AnyKeyPath: String] = [:]
}

public struct KeyPathTest {
    public static func test() {
        print("Ayyy")
        
        let migration = CreateTeacher()
        migration.add(keyPath: \.favoriteStudent, columnName: "favorite_student")
        migration.add(keyPath: \.firstName, columnName: "first_name")
        
        let migration2 = CreateStudent()
        migration2.add(keyPath: \.firstName, columnName: "first_name")
        migration2.add(keyPath: \.lastName, columnName: "last_name")
        
        ModelLookup.shared.printAll()
        
//        let jsonDecoder = JSONDecoder()
//        do {
//            try jsonDecoder.decode(Teacher.self, from: "{}".data(using: .utf8)!)
//        }
//        catch {
//            print("Error: \(error)")
//        }
        
//        let filtered = [josh, chris].filter(where: \.favoriteStudent.firstName.count, equals: 4)
//        print("There were \(filtered.count) filtered teachers.")
    }
}

extension Array where Element == Teacher {
    func filter<T: Equatable>(where key: KeyPath<Teacher, T>, equals: T) -> [Teacher] {
        print("Keypath is \(key)")
        return self.filter {
            $0[keyPath: key] == equals
        }
    }
}

///
extension String {
    func `where`(key: String, containedIn: [String]) {
        
    }
}

// 1. Get all keypaths for a model https://github.com/tensorflow/swift/blob/master/docs/DynamicPropertyIteration.md
// 2. Map them to their values
// Info: keypaths are hashable
