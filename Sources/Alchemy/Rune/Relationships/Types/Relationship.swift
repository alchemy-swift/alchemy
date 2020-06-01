import NIO

public protocol Relationship {
    associatedtype From: Model
    associatedtype To: RelationAllowed
    func load(_ from: [From], from eagerLoadKeyPath: KeyPath<From, Self>) -> EventLoopFuture<[From]>
}
