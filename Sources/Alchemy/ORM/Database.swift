public struct Database {
    public func configure() {

    }
}

extension Database: Injectable {
    public static func create(_ isMock: Bool) -> Database {
        Database()
    }
}

public extension Database {
    func add(table: Table) {

    }

    func migrate(table: Table, migration: () -> Void) {

    }
}
