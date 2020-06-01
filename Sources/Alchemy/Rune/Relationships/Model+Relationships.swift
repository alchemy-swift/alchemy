import Foundation
import NIO

/// Relationships.
extension Model {
    public typealias HasOne<To: RelationAllowed> = HasOneRelationship<Self, To>
    public typealias HasMany<To: RelationAllowed> = HasManyRelationship<Self, To>
    public typealias BelongsTo<To: RelationAllowed> = BelongsToRelationship<Self, To>
}
