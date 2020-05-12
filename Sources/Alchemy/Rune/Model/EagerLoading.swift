import NIO

extension Model {
    
}

/// An ORM query that will resolve to type `ReturnType`.
struct RuneQuery<ReturnType> {
    private let database: Database
    private let loop: EventLoop
    
    init(database: Database, loop: EventLoop) {
        self.database = database
        self.loop = loop
    }
    
    func run() -> EventLoopFuture<ReturnType> {
        self.database.query("something", values: [], on: self.loop)
    }
}
