import NIO

extension Model {
    
}

/// An ORM query that will resolve to type `ReturnType`.
final class RuneQuery<ReturnType: Model> {
    private let database: Database
    private let loop: EventLoop
    
    private var eagerLoads: [([ReturnType]) throws -> EventLoopFuture<[ReturnType]>] = []
    
    init(database: Database, loop: EventLoop) {
        self.database = database
        self.loop = loop
    }
    
    func with<R: Relationship>(_ eagerLoadKeyPath: WritableKeyPath<ReturnType, R>) {
        self.eagerLoads.append { results in
            let ids = try results.map { try $0.idField() }
            let placeholder = ids.enumerated().map { index, _ in "$\(index + 1)" }.joined(separator: ", ")
            let queryString = """
            SELECT * FROM \(R.To.Value.tableName) WHERE id IN (\(placeholder))
            """
            return self.database.query(queryString, values: ids.map { $0.value }, on: self.loop)
                .flatMapEachThrowing { try $0.decode(R.To.Value.self) }
                .map { modelResults in
                    var updatedResults = [ReturnType]()
                    
                    for (index, var result) in results.enumerated() {
                        result[keyPath: eagerLoadKeyPath] = R(value: modelResults[index])
                        updatedResults.append(result)
                    }
                    
                    return updatedResults
                }
        }
    }
    
    func run() -> EventLoopFuture<ReturnType> {
        fatalError()
    }
}
