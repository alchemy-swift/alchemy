import Foundation

extension Date {
    var elapsedString: String {
        let elapsedms = Date().timeIntervalSince(self) * 1_000
        let string = "\(elapsedms)"
        let components = string.components(separatedBy: ".")
        let whole = components[0]
        let fraction = components[safe: 1].map { $0.prefix(2) } ?? ""
        return "\(whole).\(fraction)ms"
    }
}
