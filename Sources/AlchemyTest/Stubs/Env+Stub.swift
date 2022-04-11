@testable
import Alchemy
import Foundation

extension Env {
    public static func stub(_ values: [String: String]) {
        Env.current = Env(name: "stub", dotEnvVariables: values)
    }
}
