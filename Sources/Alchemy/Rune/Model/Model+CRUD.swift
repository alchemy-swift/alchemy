import NIO

extension Model {
    static func all(db: Database = DB.default, loop: EventLoop = Loop.current)
        -> EventLoopFuture<[Self]>
    {
        self.query(database: db)
            .get(on: loop)
            .flatMapEachThrowing { try $0.decode(Self.self) }
    }
    
    /// Updates or creates the model.
    func save(db: Database = DB.default, loop: EventLoop = Loop.current) -> EventLoopFuture<Void> {
        let fields = try! self.fields()
        let columns = fields.map { $0.column }
        
        let statement = """
        INSERT INTO \(Self.tableName) (\(columns.joined(separator: ", ")))
        VALUES (\(fields.enumerated().map { index, _ in "$\(index + 1)" }.joined(separator: ", ")))
        """

        return db.query(statement, values: fields.map { $0.value }, on: loop)
            .voided()
    }
    
    /// Deletes this model from the database.
    func delete(db: Database = DB.default, loop: EventLoop = Loop.current) throws -> EventLoopFuture<Void> {
        let idField = try! self.idField()
        return try Self.query(database: db)
            .where(idField.column == idField.date())
            .delete(on: loop)
            .voided()
    }
    
    func sync() -> EventLoopFuture<Self> {
        // Refreshes this model from the database.
        fatalError()
    }
}

extension Array where Element: Model {
    func save(db: Database = DB.default, loop: EventLoop = Loop.current) -> EventLoopFuture<Void> {
        // Create or update each element in this array.
        fatalError()
    }
    
    func delete(db: Database = DB.default, loop: EventLoop = Loop.current) -> EventLoopFuture<Void> {
        // Delete all objects in this array.
        fatalError()
    }
}

extension EventLoopFuture {
    func voided() -> EventLoopFuture<Void> {
        self.map { _ in () }
    }
}

struct RuneError: Error {
    let info: String
}

/// Can't call static properties from a protocol so this is used for getting the current event loop.
public struct Loop {
    public static var current: EventLoop {
        guard let current = MultiThreadedEventLoopGroup.currentEventLoop else {
            fatalError("Unable to find an event loop associated with this thread. Try passing it in manually.")
        }
        
        return current
    }
}
