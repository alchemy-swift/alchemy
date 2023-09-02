@testable
import Alchemy
import AlchemyTest

final class EnvTests: TestCase<TestApp> {
    private let sampleEnvFile = """
        #TEST=ignore
        FOO=1
        BAR=two
            
        BAZ=
        fake
        QUOTES="three"
        """
    
    func testIsRunningTests() {
        XCTAssertTrue(Environment.isRunFromTests)
    }
    
    func testEnvLookup() {
        let env = Environment(name: "test", dotenvVariables: ["foo": "bar"])
        XCTAssertEqual(env.get("foo"), "bar")
    }
    
    func testStaticLookup() {
        let env = Environment(
            name: "test",
            dotenvVariables: [
                "foo": "one",
                "bar": "two",
            ]
        )
        XCTAssertEqual(env.get("foo"), "one")
        XCTAssertEqual(env.bar, "two")
        let wrongCase: String? = env.BAR
        XCTAssertEqual(wrongCase, nil)
    }
    
    func testLoadEnvFile() {
        let path = createTempFile(".env-fake-\(UUID().uuidString)", contents: sampleEnvFile)
        let env = Environment(name: "test", dotenvPaths: [path])
        env.loadVariables()
        XCTAssertEqual(env.FOO, "1")
        XCTAssertEqual(env.BAR, "two")
        XCTAssertEqual(env.get("TEST", as: String.self), nil)
        XCTAssertEqual(env.get("fake", as: String.self), nil)
        XCTAssertEqual(env.get("BAZ", as: String.self), nil)
        XCTAssertEqual(env.QUOTES, "three")
    }
}
