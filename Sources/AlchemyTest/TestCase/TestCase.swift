@testable import Alchemy
import XCTest

open class TestCase<A: Application>: XCTestCase {
    public var app = A()
    
    open override func setUp() {
        super.setUp()
        app = A()
        
        do {
            try app.setup(testing: true)
        } catch {
            fatalError("Error booting your app for testing: \(error)")
        }
    }
    
    open override func tearDown() {
        super.tearDown()
        app.shutdown()
        JobDecoding.reset()
    }
}

extension Application {
    func shutdown() {
        @Inject var lifecycle: ServiceLifecycle
        lifecycle.shutdown()
    }
}
