@testable
import Alchemy
import AlchemyTesting

final class EnvTests: TestCase<TestApp> {
    func testEnvLookup() {
        let env = Environment(name: "test", dotenvVariables: ["foo": "bar"])
        XCTAssertEqual(env.get("foo"), "bar")
    }

    func testLoadEnvFile() {
        let path = createTempFile(
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
        XCTAssertEqual(env.get("FOO"), "1")
        XCTAssertEqual(env.get("BAR"), "two")
        XCTAssertEqual(env.get("TEST", as: String.self), nil)
        XCTAssertEqual(env.get("fake", as: String.self), nil)
        XCTAssertEqual(env.get("BAZ", as: String.self), nil)
        XCTAssertEqual(env.get("QUOTES"), "three")
    }
}
