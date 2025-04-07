@testable
import Alchemy
import AlchemyTesting
import Foundation

struct EnvTests {
    @Test func lookup() {
        let env = Environment(name: "test", dotenvVariables: ["foo": "bar"])
        #expect(env.get("foo") == "bar")
    }

    @Test func envFile() {
        let path = FileManager.default.createTempFile(
            ".env-fake-\(UUID().uuidString)",
            contents: """
                #TEST=ignore
                FOO=1
                BAR=two
                    
                BAZ=
                fake
                QUOTES="three"
                """
        )

        let env = Environment(name: "test", dotenvPaths: [path])
        env.loadVariables()
        #expect(env.get("FOO") == "1")
        #expect(env.get("BAR") == "two")
        #expect(env.get("TEST", as: String.self) == nil)
        #expect(env.get("fake", as: String.self) == nil)
        #expect(env.get("BAZ", as: String.self) == nil)
        #expect(env.get("QUOTES") == "three")
    }
}
