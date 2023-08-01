@testable
import Alchemy
import Foundation

extension Environment {
    public static func stub(_ values: [String: String]) {
        Environment.current = Environment(name: "stub", dotenvVariables: values)
    }
}
