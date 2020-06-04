import NIO

public protocol Relationship {
    associatedtype From: Model
    associatedtype To: RelationAllowed
    
    func load(
        _ from: [From],
        with nestedQuery: @escaping (ModelQuery<To.Value>) -> ModelQuery<To.Value>,
        from eagerLoadKeyPath: KeyPath<From, Self>
    ) -> EventLoopFuture<[From]>
}
