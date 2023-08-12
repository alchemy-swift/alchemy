import Alchemy

struct Applications: Model, Codable {
    var id: PK<Int> = .new
}
