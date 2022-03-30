import Foundation
import NIO

/// Typealiases for the various relationships a `Model` can have.
extension Model {
    /// A `HasOne<To>` relationship means there is a 1-1 relationship
    /// between `Self` and `To` and that `Self` is the parent.
    public typealias HasOne<To: RelationshipAllowed> = HasOneRelationship<Self, To>
    
    /// A `HasMany<To>` relationship means that there is a 1-Many _or_
    /// M-M relationship between `Self` and `To` and that `Self` is
    /// the parent.
    public typealias HasMany<To: RelationshipAllowed> = HasManyRelationship<Self, To>
    
    /// A `BelongsTo<To>` relationship means that there is _either_ a
    /// 1-1 or 1-Many relationship between `Self` and `To` and that
    /// `Self` is the child.
    public typealias BelongsTo<To: RelationshipAllowed> = BelongsToRelationship<Self, To>
}
