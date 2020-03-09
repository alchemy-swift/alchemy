import Foundation

struct Todo: Identifiable {
    var id: UUID
    var isDone: Bool
    var name: String
    var user: ForeignKey<User>
}

struct ForeignKey<T> {
    
}

protocol Migration {}

struct UserMigration {
    
}

// Sanitize optional keypaths?
// Keypaths for forced correct type?
// Include nested layers
