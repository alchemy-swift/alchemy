class RelationshipDataStorage {
    private static var dict: [String: Any] = [:]
    
    static func store<From: Model, To: RelationAllowed>(
        from: From.Type,
        to: To.Type,
        fromStored: String,
        loadClosure: @escaping EagerLoadClosure<From, To>
    ) {
        let key = "\(From.tableName)_\(To.Value.tableName)_\(fromStored)"
        dict[key] = loadClosure
    }
    
    static func get<From: Model, To: RelationAllowed>(
        from: From.Type,
        to: To.Type,
        fromStored: String
    ) -> EagerLoadClosure<From, To>? {
        let key = "\(From.tableName)_\(To.Value.tableName)_\(fromStored)"
        return dict[key] as? EagerLoadClosure<From, To>
    }
}
