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
        XCTAssertTrue(Environment.isTest)
    }
    
    func testEnvLookup() {
        let env = Environment(name: "test", dotenvVariables: ["foo": "bar"])
        XCTAssertEqual(env.get("foo"), "bar")
    }
    
    func testStaticLookup() {
        Environment.current = Environment(name: "test", dotenvVariables: [
            "foo": "one",
            "bar": "two",
        ])
        XCTAssertEqual(Environment.get("foo"), "one")
        XCTAssertEqual(Environment.bar, "two")
        let wrongCase: String? = Environment.BAR
        XCTAssertEqual(wrongCase, nil)
    }
    
    func testEnvNameProcess() {
        Environment.boot(processEnv: ["APP_ENV": "foo"])
        XCTAssertEqual(Environment.current.name, "foo")
    }
    
    func testEnvNameArgs() {
        Environment.boot(args: ["-e", "foo"])
        XCTAssertEqual(Environment.current.name, "foo")
        Environment.boot(args: ["--env", "bar"])
        XCTAssertEqual(Environment.current.name, "bar")
        Environment.boot(args: ["--env", "baz"], processEnv: ["APP_ENV": "test"])
        XCTAssertEqual(Environment.current.name, "baz")
    }
    
    func testEnvArgsPrecedence() {
        Environment.boot(args: ["--env", "baz"], processEnv: ["APP_ENV": "test"])
        XCTAssertEqual(Environment.current.name, "baz")
    }
    
    func testLoadEnvFile() {
        let path = createTempFile(".env-fake-\(UUID().uuidString)", contents: sampleEnvFile)
        Environment.loadDotEnv(path)
        XCTAssertEqual(Environment.FOO, "1")
        XCTAssertEqual(Environment.BAR, "two")
        XCTAssertEqual(Environment.get("TEST", as: String.self), nil)
        XCTAssertEqual(Environment.get("fake", as: String.self), nil)
        XCTAssertEqual(Environment.get("BAZ", as: String.self), nil)
        XCTAssertEqual(Environment.QUOTES, "three")
    }
    
    func testProcessPrecedence() {
        let path = createTempFile(".env-fake-\(UUID().uuidString)", contents: sampleEnvFile)
        Environment.boot(args: ["-e", path], processEnv: ["FOO": "2"])
        XCTAssertEqual(Environment.FOO, "2")
    }
    
    func testWarnDerivedData() {
        Environment.warnIfUsingDerivedData("/Xcode/DerivedData")
    }
}
