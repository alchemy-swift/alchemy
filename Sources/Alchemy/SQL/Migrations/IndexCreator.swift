import Foundation

protocol IndexCreator: class {
    var createIndexes: [CreateIndex] { get set }
}

struct CreateIndex {
    let columns: [String]
    let isUnique: Bool
}

extension IndexCreator {
    func addIndex(columns: [String], isUnique: Bool) {
        self.createIndexes.append(CreateIndex(columns: columns, isUnique: isUnique))
    }
}
