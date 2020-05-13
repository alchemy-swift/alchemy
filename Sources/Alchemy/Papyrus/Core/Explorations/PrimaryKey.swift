public struct PK<Type: PKIdentifiable>: Codable {
    private let val: Type.PKType
    public init(_ obj: Type) {
        self.val = obj.id
    }
}

public protocol PKIdentifiable where PKType: Codable {
    associatedtype PKType
    var id: PKType { get }
}

public extension PKIdentifiable {
    var pk: PK<Self> { return PK(self) }
}

//public struct User: Codable, Authable, PKIdentifiable {
//    public var id: String
//    var username: String
//    var hashedPassword: String
//
//    func test() {
////        let user = User(id: "", username: "", hashedPassword: "")
////        let rem = Reminder(userID: user.pk, name: "yeet", isComplete: true)
//    }
//}

//struct Reminder: Codable {
//    var userID: PK<User>
//    var name: String
//    var isComplete: Bool
//}
