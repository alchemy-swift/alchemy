@testable
import Alchemy
import Foundation

extension Environment {
    public static func stub(_ values: [String: String]) {
        Container.register(Environment(name: "stub", dotenvVariables: values)).singleton()
    }
}
