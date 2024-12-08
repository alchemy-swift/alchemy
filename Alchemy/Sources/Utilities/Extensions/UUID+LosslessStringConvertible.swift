import Foundation

extension UUID: @retroactive LosslessStringConvertible {
    public init?(_ description: String) {
        self.init(uuidString: description)
    }
}
