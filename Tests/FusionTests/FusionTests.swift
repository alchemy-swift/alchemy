@testable import Fusion
import XCTest

final class FusionTest: XCTestCase {
    var container: Container = Container()
    
    override func setUp() {
        super.setUp()
        self.container = Container()
    }
    
    func testTransient() {
        let exp = self.expectation(description: "called 3x")
        exp.expectedFulfillmentCount = 3
        self.container.register(String.self) { _ in
            exp.fulfill()
            return "Testing1"
        }
        
        XCTAssertEqual(self.container.resolve(String.self), "Testing1")
        XCTAssertEqual(self.container.resolve(String.self), "Testing1")
        XCTAssertEqual(self.container.resolve(String.self), "Testing1")
        
        self.waitForExpectations(timeout: 0)
    }
    
    func testSingleton() {
        let exp = self.expectation(description: "called 1x")
        exp.expectedFulfillmentCount = 1
        self.container.register(singleton: String.self) { _ in
            exp.fulfill()
            return "Testing2"
        }
        
        XCTAssertEqual(self.container.resolve(String.self), "Testing2")
        XCTAssertEqual(self.container.resolve(String.self), "Testing2")
        XCTAssertEqual(self.container.resolve(String.self), "Testing2")
        
        self.waitForExpectations(timeout: 0)
    }
    
    func testSingletonIdentified() {
        let exp = self.expectation(description: "called 1x")
        exp.expectedFulfillmentCount = 1
        self.container.register(singleton: String.self, identifier: "test") { _ in
            exp.fulfill()
            return "Testing3"
        }
        
        XCTAssertEqual(self.container.resolveOptional(String.self), nil)
        XCTAssertEqual(self.container.resolveOptional(String.self, identifier: "foo"), nil)
        XCTAssertEqual(self.container.resolve(String.self, identifier: "test"), "Testing3")
        
        self.waitForExpectations(timeout: 0)
    }
    
    func testContainer() {
        let childContainer = Container(parent: self.container)
        
        self.container.register(singleton: String.self) { _ in "Testing4" }
        childContainer.register(singleton: Int.self) { _ in 4 }
        
        XCTAssertEqual(childContainer.resolve(String.self), "Testing4")
        XCTAssertEqual(childContainer.resolve(Int.self), 4)
        XCTAssertEqual(self.container.resolveOptional(Int.self), nil)
    }
    
    func testDependency() {
        self.container.register(String.self) { _ in "5" }
        self.container.register(Int.self) { container in
            return Int(container.resolve(String.self))!
        }
        
        XCTAssertEqual(self.container.resolve(String.self), "5")
        XCTAssertEqual(self.container.resolve(Int.self), 5)
    }
    
    func testContainerized() {
        let container = Container()
        container.register(String.self, factory: { _ in "Testing6" })
        container.register(Int.self, factory: { _ in 6 })
        container.register(singleton: Bool.self, identifier: true, factory: { _ in true })
        container.register(singleton: Bool.self, identifier: false, factory: { _ in false })
        
        let instance = TestingContainerized(container: container)
        XCTAssertEqual(instance.string, "Testing6")
        XCTAssertEqual(instance.int, 6)
        XCTAssertEqual(instance.boolTrue, true)
        XCTAssertEqual(instance.boolFalse, false)
    }
}

private final class TestingContainerized: Containerized {
    var container: Container
    
    @Inject
    var string: String
    
    @Inject
    var int: Int
    
    @Inject(true)
    var boolTrue: Bool
    
    @Inject(false)
    var boolFalse: Bool
    
    init(container: Container) {
        self.container = container
    }
}
