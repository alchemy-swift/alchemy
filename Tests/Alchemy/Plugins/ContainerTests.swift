@testable import Alchemy
import XCTest

final class ContainerTests: XCTestCase {
    var container: Container { .main }

    override func setUp() {
        super.setUp()
        container.reset()
    }

    func testTransient() {
        let exp = expectation(description: "called 3x")
        exp.expectedFulfillmentCount = 3
        container.register { _ in
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
        container.register { _ in
            exp.fulfill()
            return "Testing2"
        }.singleton()

        XCTAssertEqual(container.resolve(String.self), "Testing2")
        XCTAssertEqual(container.resolve(String.self), "Testing2")
        XCTAssertEqual(container.resolve(String.self), "Testing2")
        waitForExpectations(timeout: 0)
    }

    func testSingletonIdentified() {
        let exp = expectation(description: "called 1x")
        exp.expectedFulfillmentCount = 1
        container.register(factory: { _ in
            exp.fulfill()
            return "Testing3"
        }, id: "test").singleton()

        XCTAssertEqual(container.resolve(String.self), nil)
        XCTAssertEqual(container.resolve(String.self, id: "foo"), nil)
        XCTAssertEqual(container.resolve(String.self, id: "test"), "Testing3")
        waitForExpectations(timeout: 0)
    }

    func testOverride() {
        container.register("Testing1").singleton()
        XCTAssertEqual(container.resolve(String.self), "Testing1")
        container.register("Testing2").singleton()
        XCTAssertEqual(container.resolve(String.self), "Testing2")
        container.register("Testing3")
        XCTAssertEqual(container.resolve(String.self), "Testing3")
        container.register("Testing4")
        XCTAssertEqual(container.resolve(String.self), "Testing4")
        container.register("Testing5").singleton()
        XCTAssertEqual(container.resolve(String.self), "Testing5")
        container.register("Testing6").singleton()
        XCTAssertEqual(container.resolve(String.self), "Testing6")
    }

    func testContainer() {
        let childContainer = Container(parent: container)
        container.register(factory: { _ in "Testing4" }).singleton()
        childContainer.register(factory: { _ in 4 }).singleton()
        XCTAssertEqual(childContainer.resolve(String.self), "Testing4")
        XCTAssertEqual(childContainer.resolve(Int.self), 4)
        XCTAssertEqual(container.resolve(Int.self), nil)
    }

    func testDependency() {
        container.register("5")
        container.register { container in
            return Int(container.resolve(String.self)!)!
        }

        XCTAssertEqual(container.resolve(String.self), "5")
        XCTAssertEqual(container.resolve(Int.self), 5)
    }

    func testDefault() {
        Container.main.register(factory: { _ in "Testing6" })
        Container.main.register(factory: { _ in 6 })
        let instance = TestingDefault()
        XCTAssertEqual(instance.string, "Testing6")
        XCTAssertEqual(instance.int, 6)
    }

    func testContainerized() {
        let container = Container()
        container.register { _ in "Testing7" }
        container.register { _ in 6 }
        container.register(factory: { _ in true }, id: true)
        container.register(factory: { _ in false }, id: false)

        let instance = TestingContainerized(container: container)
        XCTAssertEqual(instance.string, "Testing7")
        XCTAssertEqual(instance.int, 6)
        XCTAssertEqual(instance.boolTrue, true)
        XCTAssertEqual(instance.boolFalse, false)
    }

    func testProperlyCastNilToHashable() {
        container.register("cat").singleton()
        XCTAssertEqual(container.resolve(String.self), "cat")
    }

    func testInject() {
        container.register("foo")
        container.register("bar", id: 1)
        container.register("baz", id: 2)

        @Inject    var string1: String
        @Inject(1) var string2: String
        @Inject(2) var string3: String

        XCTAssertEqual(string1, "foo")
        XCTAssertEqual(string2, "bar")
        XCTAssertEqual(string3, "baz")
    }

    func testThrowing() throws {
        container.register(1)
        XCTAssertEqual(try container.resolveOrThrow(Int.self), 1)
        XCTAssertThrowsError(try container.resolveOrThrow(String.self))
        XCTAssertThrowsError(try Container.resolveOrThrow(String.self))
    }

    func testStatic() throws {
        Container.register(1)
        Container.register { "\($0.require(Int.self))" }
        Container.register { 1.2 }
        XCTAssertNil(Container.resolve(Bool.self))
        XCTAssertEqual(Container.resolve(), "1")
        XCTAssertEqual(Container.resolve(), 1.2)
        XCTAssertEqual(try Container.resolveOrThrow(), 1)
        XCTAssertEqual(Container.require(), "1")
    }

    func testDebug() {
        container.register("foo").singleton()
        container.register(0, id: 1)
        container.register(false, id: 2)
        XCTAssertEqual(container.debugDescription, """
        * Container *
        - Bool (2): false (transient)
        - Int (1): 0 (transient)
        - String: foo (singleton)
        """)
    }

    func testDebugEmpty() {
        XCTAssertEqual(container.debugDescription, """
        * Container *
        <nothing registered>
        """)
    }

    func testKeyPath() {
        let keyPath = \TestingDefault.string
        XCTAssertEqual(container.exists(keyPath), false)
        container.set(keyPath, value: "foo")
        XCTAssertEqual(container.get(keyPath), "foo")
        XCTAssertEqual(container.require(keyPath), "foo")
        XCTAssertEqual(container.exists(keyPath), true)
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
