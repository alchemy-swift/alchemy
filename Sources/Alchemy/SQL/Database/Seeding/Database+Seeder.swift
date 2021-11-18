extension Database {
    /// Seeds the database by running each seeder in `seeders`
    /// consecutively.
    public func seed() async throws {
        for seeder in seeders {
            try await seeder.run()
        }
    }
    
    public func seed(with seeder: Seeder) async throws {
        try await seeder.run()
    }
    
    func seed(names seederNames: [String]) async throws {
        let toRun = try seederNames.map { name in
            return try seeders
                .first(where: {
                    $0.name.lowercased() == name.lowercased() ||
                    $0.name.lowercased().droppingSuffix("seeder") == name.lowercased()
                })
                .unwrap(or: DatabaseError("Unable to find a seeder on this database named \(name) or \(name)Seeder."))
        }
        
        for seeder in toRun {
            try await seeder.run()
        }
    }
}

extension Seeder {
    fileprivate var name: String {
        Alchemy.name(of: Self.self)
    }
}
