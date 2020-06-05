import NIO

public protocol AnyBelongsTo {}

@propertyWrapper
/// The child of a one to many or a one to one.
public final class BelongsToRelationship<Child: Model, Parent: RelationAllowed>: AnyBelongsTo, Codable, Relationship {
    public typealias From = Child
    public typealias To = Parent
    
    public var id: Parent.Value.Identifier! {
        didSet {
            self.value = nil
        }
    }

    private var value: Parent?
    
    public var wrappedValue: Parent {
        get {
            guard let value = self.value else { fatalError("Relationship was not loaded!") }
            return value
        }
        set { self.value = newValue }
    }

    public init(_ parentID: Parent.Value.Identifier) {
        self.id = parentID
    }
    
    public init(_ parent: Parent.Value) {
        guard let id = parent.id else {
            fatalError("Can't form a relation with an unidentified object.")
        }

        self.id = id
    }

    public var projectedValue: BelongsToRelationship<Child, Parent> {
        self
    }

    public func load(
        _ from: [Child],
        with nestedQuery: @escaping (ModelQuery<Parent.Value>) -> ModelQuery<Parent.Value>,
        from eagerLoadKeyPath: KeyPath<Child, Child.BelongsTo<Parent>>) -> EventLoopFuture<[Child]>
    {
        let parentIDs = from.compactMap { $0[keyPath: eagerLoadKeyPath].id }.uniques
        let initialQuery = Parent.Value.query().where(key: "id", in: parentIDs)
        return nestedQuery(initialQuery)
            .getAll()
            .flatMapThrowing { parents in
                var updatedResults = [Child]()
                let dict = Dictionary(grouping: parents, by: { $0.id! })
                for child in from {
                    let parentID = child[keyPath: eagerLoadKeyPath].id!
                    let parent = dict[parentID]
                    child[keyPath: eagerLoadKeyPath].wrappedValue = try Parent.from(parent?.first)
                    updatedResults.append(child)
                }

                return updatedResults
            }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.id)
    }
    
    public init(from decoder: Decoder) throws {
        self.id = try decoder.singleValueContainer().decode(Parent.Value.Identifier.self)
    }
}
