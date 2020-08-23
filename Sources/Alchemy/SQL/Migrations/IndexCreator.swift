import Foundation

protocol IndexCreator: class {
    var createIndices: [CreateIndex] { get set }
}

struct CreateIndex {
    let columns: [String]
    let isUnique: Bool
}

extension IndexCreator {
    func addIndex(columns: [String], isUnique: Bool) {
        self.createIndices.append(CreateIndex(columns: columns, isUnique: isUnique))
    }
}
