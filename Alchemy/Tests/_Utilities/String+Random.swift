import Foundation

extension String {
    static var random: String {
        UUID().uuidString
    }
}
