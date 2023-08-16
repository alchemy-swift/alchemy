import Alchemy

struct Applications: Model, Codable {
    static var storedProperties: [PartialKeyPath<Applications> : String] = [
        \Applications.id: "id",
    ]

    var id: PK<Int> = .new
}
