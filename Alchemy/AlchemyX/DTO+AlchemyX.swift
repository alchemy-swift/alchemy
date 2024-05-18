import AlchemyX

public struct DTOController<D: Resource>: Controller where D.Identifier: SQLValueConvertible & LosslessStringConvertible {
    let db: Database
    let tableName: String

    var table: Query<SQLRow> {
        db.table(tableName)
    }

    public func route(_ router: Router) {
        let pathWithId = D.path + "/:id"
        router
            .get(D.path, use: getAll)
            .get(pathWithId, use: getOne)
            .post(D.path, use: create)
            .patch(pathWithId, use: update)
            .delete(pathWithId, use: delete)
    }

    private func getAll(req: Request) async throws -> [D] {
        return try await table.get().decodeEach(keyMapping: db.keyMapping)
    }

    private func getOne(req: Request) async throws -> D {
        let id: D.ID = try req.requireParameter("id")
        guard let row = try await table.where("id" == id).first() else {
            throw HTTPError(.notFound)
        }

        return try row.decode(keyMapping: db.keyMapping)
    }

    private func create(req: Request) async throws -> D {
        let dto = try req.decode(D.self)
        return try await table.insertReturn(dto).decode(keyMapping: db.keyMapping)
    }

    private func update(req: Request) async throws -> D {
        let id: D.ID = try req.requireParameter("id")

        guard req.content.error == nil else {
            throw HTTPError(.badRequest)
        }

        // 0. update the row with req fields

        let query = table.where("id" == id)
        try await query.update(req.content)

        // 1. return the updated row

        guard let first = try await query.first() else {
            throw HTTPError(.notFound)
        }

        return try first.decode(keyMapping: db.keyMapping)
    }

    private func delete(req: Request) async throws {
        let id: D.ID = try req.requireParameter("id")
        guard try await table.where("id" == id).exists() else {
            throw HTTPError(.notFound)
        }

        try await table.where("id" == id).delete()
    }
}

public extension Router {
    @discardableResult
    func useResource<D: Resource>(_ type: D.Type) -> Self where D.Identifier: SQLValueConvertible & LosslessStringConvertible {
        use(type.controller())
    }
}

fileprivate extension Resource where Identifier: SQLValueConvertible & LosslessStringConvertible {
    static func controller(db: Database = DB, table: String = "\(Self.self)".lowercased().pluralized) -> Controller {
        DTOController<Self>(db: db, tableName: table)
    }
}
