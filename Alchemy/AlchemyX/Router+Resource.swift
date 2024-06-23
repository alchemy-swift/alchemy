import AlchemyX
import Pluralize

extension Application {
    @discardableResult
    public func useResource<R: Resource>(
        _ type: R.Type,
        db: Database = DB,
        table: String = "\(R.self)".lowercased().pluralized,
        updateTable: Bool = false
    ) -> Self where R.Identifier: SQLValueConvertible & LosslessStringConvertible {
        use(ResourceController<R>(db: db, tableName: table))
        if updateTable {
            Lifecycle.register(
                label: "Migrate_\(R.self)",
                start: .async { try await db.updateSchema(R.self) },
                shutdown: .none
            )
        }

        return self
    }
}

extension Router {
    @discardableResult
    public func useResource<R: Resource>(
        _ type: R.Type,
        db: Database = DB,
        table: String = "\(R.self)".lowercased().pluralized
    ) -> Self where R.Identifier: SQLValueConvertible & LosslessStringConvertible {
        use(ResourceController<R>(db: db, tableName: table))
    }
}

private struct ResourceController<R: Resource>: Controller
    where R.Identifier: SQLValueConvertible & LosslessStringConvertible
{
    let db: Database
    let tableName: String

    private var table: Query<SQLRow> {
        db.table(tableName)
    }

    public func route(_ router: Router) {
        router
            .use(Token.tokenAuthMiddleware())
            .post(R.path + "/create", use: create)
            .post(R.path, use: getAll)
            .get(R.path + "/:id", use: getOne)
            .patch(R.path + "/:id", use: update)
            .delete(R.path + "/:id", use: delete)
    }

    private func getAll(req: Request) async throws -> [R] {
        var query = table
        if let queryParameters = try req.decode(QueryParameters?.self) {
            for filter in queryParameters.filters {
                query = query.filter(filter, keyMapping: db.keyMapping)
            }

            for sort in queryParameters.sorts {
                query = query.sort(sort, keyMapping: db.keyMapping)
            }
        }

        return try await query
            .ownedBy(req.user)
            .get()
            .decodeEach(keyMapping: db.keyMapping)
    }

    private func getOne(req: Request) async throws -> R {
        let id: R.ID = try req.requireParameter("id")
        guard let row = try await model(id).first() else {
            throw HTTPError(.notFound)
        }

        return try row.decode(keyMapping: db.keyMapping)
    }

    private func create(req: Request) async throws -> R {
        let resource = try req.decode(R.self)
        var fields = try resource.sqlFields()
        fields["user_id"] = try SQLValue.uuid(req.user.id)
        return try await table
            .insertReturn(fields)
            .decode(keyMapping: db.keyMapping)
    }

    private func update(req: Request) async throws -> R {
        let id: R.ID = try req.requireParameter("id")

        guard req.content.error == nil else {
            throw HTTPError(.badRequest)
        }

        // 0. update the row with req fields

        try await model(id).update(req.content)

        // 1. return the updated row

        guard let first = try await model(id).first() else {
            throw HTTPError(.notFound)
        }

        return try first.decode(keyMapping: db.keyMapping)
    }

    private func delete(req: Request) async throws {
        let id: R.ID = try req.requireParameter("id")
        guard try await model(id).exists() else {
            throw HTTPError(.notFound)
        }

        try await model(id).delete()
    }

    private func model(_ id: R.Identifier?) throws -> Query<SQLRow> {
        try table.where("id" == id).ownedBy(req.user)
    }
}

extension Query {
    fileprivate func filter(_ filter: QueryParameters.Filter, keyMapping: KeyMapping) -> Self {
        let op: SQLWhere.Operator = switch filter.op {
        case .contains: .like
        case .equals: .equals
        case .greaterThan: .greaterThan
        case .greaterThanEquals: .greaterThanOrEqualTo
        case .lessThan: .lessThan
        case .lessThanEquals: .lessThanOrEqualTo
        case .notEquals: .notEqualTo
        }

        let field = keyMapping.encode(filter.field)
        let value = filter.op == .contains ? "%\(filter.value)%" : filter.value
        return `where`(field, op, value)
    }

    fileprivate func sort(_ sort: QueryParameters.Sort, keyMapping: KeyMapping) -> Self {
        let field = keyMapping.encode(sort.field)
        return orderBy(field, direction: sort.ascending ? .asc : .desc)
    }
}

extension Request {
    fileprivate var user: User { get throws { try get() } }
}


extension Query {
    fileprivate func ownedBy(_ user: User) throws -> Self {
        return `where`("user_id" == user.id)
    }
}
