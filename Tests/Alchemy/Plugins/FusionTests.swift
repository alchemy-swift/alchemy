@testable import Fusion
import XCTest

final class FusionTest: XCTestCase {
    var container = Container()

    override func setUp() {
        super.setUp()
        Container.main = Container()
        container = .main
    }

    func testTransient() {
        let exp = expectation(description: "called 3x")
        exp.expectedFulfillmentCount = 3
        container.bind(to: String.self) { _ in
            exp.fulfill()
            return "Testing1"
        }

        XCTAssertEqual(container.resolve(String.self), "Testing1")
        XCTAssertEqual(container.resolve(String.self), "Testing1")
        XCTAssertEqual(container.resolve(String.self), "Testing1")
        waitForExpectations(timeout: 0)
    }

    func testSingleton() {
        let exp = expectation(description: "called 1x")
        exp.expectedFulfillmentCount = 1
        container.bind(.singleton, to: String.self) { _ in
            exp.fulfill()
            return "Testing2"
        }

        XCTAssertEqual(container.resolve(String.self), "Testing2")
        XCTAssertEqual(container.resolve(String.self), "Testing2")
        XCTAssertEqual(container.resolve(String.self), "Testing2")
        waitForExpectations(timeout: 0)
    }

    func testSingletonIdentified() {
        let exp = expectation(description: "called 1x")
        exp.expectedFulfillmentCount = 1
        container.bind(.singleton, to: String.self, id: "test") { _ in
            exp.fulfill()
            return "Testing3"
        }

        XCTAssertEqual(container.resolve(String.self), nil)
        XCTAssertEqual(container.resolve(String.self, id: "foo"), nil)
        XCTAssertEqual(container.resolve(String.self, id: "test"), "Testing3")
        waitForExpectations(timeout: 0)
    }

    func testOverride() {
        container.bind(.singleton, value: "Testing1")
        XCTAssertEqual(container.resolve(String.self), "Testing1")
        container.bind(.singleton, value: "Testing2")
        XCTAssertEqual(container.resolve(String.self), "Testing2")
        container.bind(value: "Testing3")
        XCTAssertEqual(container.resolve(String.self), "Testing3")
        container.bind(value: "Testing4")
        XCTAssertEqual(container.resolve(String.self), "Testing4")
        container.bind(.singleton, value: "Testing5")
        XCTAssertEqual(container.resolve(String.self), "Testing5")
        container.bind(.singleton, value: "Testing6")
        XCTAssertEqual(container.resolve(String.self), "Testing6")
    }

    func testContainer() {
        let childContainer = Container(parent: container)
        container.bind(.singleton, to: String.self) { _ in "Testing4" }
        childContainer.bind(.singleton, to: Int.self) { _ in 4 }
        XCTAssertEqual(childContainer.resolve(String.self), "Testing4")
        XCTAssertEqual(childContainer.resolve(Int.self), 4)
        XCTAssertEqual(container.resolve(Int.self), nil)
    }

    func testDependency() {
        container.bind(value: "5")
        container.bind { container in
            return Int(container.resolve(String.self)!)!
        }

        XCTAssertEqual(container.resolve(String.self), "5")
        XCTAssertEqual(container.resolve(Int.self), 5)
    }

    func testDefault() {
        Container.main.bind(to: String.self, factory: { _ in "Testing6" })
        Container.main.bind(to: Int.self, factory: { _ in 6 })
        let instance = TestingDefault()
        XCTAssertEqual(instance.string, "Testing6")
        XCTAssertEqual(instance.int, 6)
    }

    func testContainerized() {
        let container = Container()
        container.bind(to: String.self) { _ in "Testing7" }
        container.bind(to: Int.self) { _ in 6 }
        container.bind(.singleton, id: true) { _ in true }
        container.bind(.singleton, id: false) { _ in false }

        let instance = TestingContainerized(container: container)
        XCTAssertEqual(instance.string, "Testing7")
        XCTAssertEqual(instance.int, 6)
        XCTAssertEqual(instance.boolTrue, true)
        XCTAssertEqual(instance.boolFalse, false)
    }

    func testProperlyCastNilToHashable() {
        container.bind(.singleton, id: nil, value: "cat")
        XCTAssertEqual(container.resolve(String.self), "cat")
    }

    func testInject() {
        container.bind(value: "foo")
        container.bind(id: 1, value: "bar")
        container.bind(id: 2, value: "baz")

        @Inject    var string1: String
        @Inject(1) var string2: String
        @Inject(2) var string3: String

        XCTAssertEqual(string1, "foo")
        XCTAssertEqual(string2, "bar")
        XCTAssertEqual(string3, "baz")
    }

    func testThrowing() throws {
        container.bind(value: 1)
        XCTAssertEqual(try container.resolveThrowing(Int.self), 1)
        XCTAssertThrowsError(try container.resolveThrowing(String.self))
        XCTAssertThrowsError(try Container.resolveThrowing(String.self))
    }

    func testStatic() throws {
        Container.bind(value: 1)
        Container.bind { "\($0.resolveAssert(Int.self))" }
        XCTAssertNil(Container.resolve(Bool.self))
        XCTAssertEqual(Container.resolve(String.self), "1")
        XCTAssertEqual(try Container.resolveThrowing(Int.self), 1)
        XCTAssertEqual(Container.resolveAssert(String.self), "1")
    }

    func testDebug() {
        container.bind(.singleton, value: "foo")
        container.bind(id: 1, value: 0)
        container.bind(id: 2, value: false)
        XCTAssertEqual(container.debugDescription, """
        *Container Entries*
        - Bool (2): false (transient)
        - Int (1): 0 (transient)
        - String: foo (singleton)
        """)
    }

    func testDebugEmpty() {
        XCTAssertEqual(container.debugDescription, """
        *Container Entries*
        <nothing registered>
        """)
    }
}

private final class TestingDefault {
    @Inject var string: String
    @Inject var int: Int
}

private final class TestingContainerized: Containerized {
    let container: Container

    @Inject        var string: String
    @Inject        var int: Int
    @Inject(true)  var boolTrue: Bool
    @Inject(false) var boolFalse: Bool

    init(container: Container) {
        self.container = container
    }
}
