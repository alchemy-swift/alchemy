import NIO

public protocol AnyHas {}

public class HasRelationship<From: Model, To: RelationAllowed>: AnyHas, Decodable {
    var eagerLoadClosure: EagerLoadClosure<From, To>!
    
    init() {}
    
    public required init(this: String, to key: String, via: KeyPath<To.Value, To.Value.BelongsTo<From>>) {
        let loadClosure = EagerLoader<From, To>.via(key: via, keyString: key)
        self.eagerLoadClosure = loadClosure
        
        RelationshipDataStorage.store(
            from: From.self,
            to: To.self,
            fromStored: this,
            loadClosure: loadClosure
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
