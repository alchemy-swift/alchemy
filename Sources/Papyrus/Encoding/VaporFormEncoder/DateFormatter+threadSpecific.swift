import Foundation

extension ISO8601DateFormatter {
    static var threadSpecific: ISO8601DateFormatter {
        ISO8601DateFormatter()
    }
}
