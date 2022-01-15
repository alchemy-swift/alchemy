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
        XCTAssertTrue(Env.isTest)
    }
    
    func testEnvLookup() {
        let env = Env(name: "test", dotEnvVariables: ["foo": "bar"])
        XCTAssertEqual(env.get("foo"), "bar")
    }
    
    func testStaticLookup() {
        Env.current = Env(name: "test", dotEnvVariables: [
            "foo": "one",
            "bar": "two",
        ])
        XCTAssertEqual(Env.get("foo"), "one")
        XCTAssertEqual(Env.bar, "two")
        let wrongCase: String? = Env.BAR
        XCTAssertEqual(wrongCase, nil)
    }
    
    func testEnvNameProcess() {
        Env.boot(processEnv: ["APP_ENV": "foo"])
        XCTAssertEqual(Env.current.name, "foo")
    }
    
    func testEnvNameArgs() {
        Env.boot(args: ["-e", "foo"])
        XCTAssertEqual(Env.current.name, "foo")
        Env.boot(args: ["--env", "bar"])
        XCTAssertEqual(Env.current.name, "bar")
        Env.boot(args: ["--env", "baz"], processEnv: ["APP_ENV": "test"])
        XCTAssertEqual(Env.current.name, "baz")
    }
    
    func testEnvArgsPrecedence() {
        Env.boot(args: ["--env", "baz"], processEnv: ["APP_ENV": "test"])
        XCTAssertEqual(Env.current.name, "baz")
    }
    
    func testLoadEnvFile() {
        let path = createTempFile(".env-fake-\(UUID().uuidString)", contents: sampleEnvFile)
        Env.loadDotEnv(path)
        XCTAssertEqual(Env.FOO, "1")
        XCTAssertEqual(Env.BAR, "two")
        XCTAssertEqual(Env.get("TEST", as: String.self), nil)
        XCTAssertEqual(Env.get("fake", as: String.self), nil)
        XCTAssertEqual(Env.get("BAZ", as: String.self), nil)
        XCTAssertEqual(Env.QUOTES, "three")
    }
    
    func testProcessPrecedence() {
        let path = createTempFile(".env-fake-\(UUID().uuidString)", contents: sampleEnvFile)
        Env.boot(args: ["-e", path], processEnv: ["FOO": "2"])
        XCTAssertEqual(Env.FOO, "2")
    }
    
    func testWarnDerivedData() {
        Env.warnIfUsingDerivedData("/Xcode/DerivedData")
    }
}
