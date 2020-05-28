import NIO

extension Model {
    static func all(db: Database = DB.default, loop: EventLoop = Loop.current)
        -> EventLoopFuture<[Self]>
    {
        Self.query(database: db)
            .get(on: loop)
    }
    
    /// Updates or creates the model.
    func save(db: Database = DB.default, loop: EventLoop = Loop.current) -> EventLoopFuture<Void> {
        catchError {
            let fields = try self.fields()
            if self.existsInDatabase {
                let setString = fields
                    .compactMap { $0.column != "id" ? $0 : nil }
                    .enumerated()
                    .map { index, value in "\(value.column) = $\(index + 1)" }
                    .joined(separator: ", ")

                let statement = """
                UPDATE \(Self.tableName)
                SET \(setString)
                WHERE id = $\(fields.count)
                """

                return db.runQuery(statement, values: fields.map { $0.value } + [], on: loop)
                    .voided()
            } else {
                let columnsString = fields.map { $0.column }.joined(separator: ", ")
                let valuesString = fields.enumerated()
                    .map { index, _ in "$\(index + 1)" }
                    .joined(separator: ", ")

                let statement = """
                INSERT INTO \(Self.tableName) (\(columnsString))
                VALUES (\(valuesString))
                """
                return db.runQuery(statement, values: fields.map { $0.value }, on: loop)
                    .voided()
            }
        }
    }
    
    /// Deletes this model from the database.
    func delete(db: Database = DB.default, loop: EventLoop = Loop.current) -> EventLoopFuture<Void> {
        catchError(on: loop) {
            let idField = try self.idField()
            return Self.query(database: db)
                .where(WhereValue(key: idField.column, op: .equals, value: idField.value))
                .delete(on: loop)
                .voided()
        }
    }
    
    func sync() -> EventLoopFuture<Self> {
        // Refreshes this model from the database.
        fatalError()
    }
}

extension Model {
    /// Whether the model exists in the database already. Currently just whether the id is nil.
    var existsInDatabase: Bool {
        self.id != nil
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
    
    func sync() -> EventLoopFuture<Self> {
        // Refreshes this model from the database.
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

protocol OptionalProtocol {
    var optionalValue: Self? { get }
}

extension Optional: OptionalProtocol {
    var optionalValue: Optional<Wrapped>? { self }
}
