import NIO

extension Model {
    static func all(db: Database = DB.default, loop: EventLoop = Loop.current)
        -> EventLoopFuture<[Self]>
    {
        db.rawQuery("SELECT * FROM \(Self.tableName)", on: loop)
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
    
//    func delete() -> EventLoopFuture<Void> {
//
//    }
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
struct Loop {
    static var current: EventLoop {
        guard let current = MultiThreadedEventLoopGroup.currentEventLoop else {
            fatalError("Unable to find an event loop associated with this thread. Try passing it in manually.")
        }
        
        return current
    }
}
