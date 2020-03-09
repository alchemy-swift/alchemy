struct Database {
    func configure() {

    }
}

extension Database: Injectable {
    static func create(_ isMock: Bool) -> Database {
        Database()
    }
}
