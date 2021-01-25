import Foundation

public struct JSONData: Codable {
    let data: Data
}

extension JSONData: Parameter {
    public var value: DatabaseValue { .json(self.data) }
}
