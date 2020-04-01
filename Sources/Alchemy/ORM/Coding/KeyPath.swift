/// Can we form an SQL query string through a function chain that only accepts a `KeyPath` representing the
/// database field to work with. Both the `Root` and `Value` of the `KeyPath` are guaranteed to be `Codable`.

/// use: https://github.com/vapor/codable-kit

import Foundation

struct Teacher: Codable {
    var firstName: String
//    var officeNumber: Int
//    var officeBuilding: OfficeBuilding
    var favoriteStudent: Student
}

struct Student: Codable {
    var firstName: String
    var lastName: String
}

enum OfficeBuilding: String, Codable {
    case library
    case manchesterHall
    case studentRecCenter
}

public struct KeyPathTest {
    public static func test() {
        let josh = Teacher(firstName: "Josh", favoriteStudent: Student(firstName: "Leeroy", lastName: "Jenkins"))
        let chris = Teacher(firstName: "Chris", favoriteStudent: Student(firstName: "Donald", lastName: "Trump"))
        
        let filtered = [josh, chris].filter(where: \.favoriteStudent.firstName.count, equals: 4)
        print("There were \(filtered.count) filtered teachers.")
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
