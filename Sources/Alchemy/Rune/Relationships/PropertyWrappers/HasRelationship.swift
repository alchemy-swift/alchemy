import NIO

public protocol AnyHas {}

public class HasRelationship<From: Model, To: RelationAllowed>: AnyHas, Decodable {
    var eagerLoadClosure: NestedEagerLoadClosure<From, To>!
    
    init() {}
    
    public required init(this: String, to key: KeyPath<To.Value, To.Value.BelongsTo<From>>, keyString: String) {
        self.eagerLoadClosure = { EagerLoader<From, To>.via(key: key, keyString: keyString, nestedQuery: $0!) }
        
        RelationshipDataStorage.store(
            from: From.self,
            to: To.self,
            fromStored: this,
            loadClosure: self.eagerLoadClosure
        )
    }
    
    public required init<Through: Model>(
        named: String,
        from fromKey: KeyPath<Through, Through.BelongsTo<From.Value>>,
        to toKey: KeyPath<Through, Through.BelongsTo<To.Value>>,
        fromString: String,
        toString: String
    ) {
        self.eagerLoadClosure = {
            EagerLoader<From, To>.through(
                named: named,
                from: fromKey,
                to: toKey,
                fromString: fromString,
                toString: toString,
                nestedQuery: $0
            )
        }

        RelationshipDataStorage.store(
            from: From.self,
            to: To.self,
            fromStored: named,
            loadClosure: self.eagerLoadClosure
        )
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let codingKey = try container.decode(String.self)
        
        guard let loadClosure = RelationshipDataStorage.get(
                from: From.self,
                to: To.self,
                fromStored: codingKey
            ) else { fatalError("Unable to find the data of this relationship ;_;") }
        
        self.eagerLoadClosure = loadClosure
    }
}
