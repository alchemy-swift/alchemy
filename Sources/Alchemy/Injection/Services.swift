/// How to get this to work nicely with protocols?
/// eg....
/// protocol SomeService { ... }
/// protocol SomeServiceProvider: SomeService { ... }
/// protocol SomeServiceMock: SomeService { ... }

// Use cases
// 1. A singleton, i.e. a redis cache.
// 2. One of a few, i.e. there are multiple databases.
// 3. Varies on the fly, i.e. a specific ViewModel. // probably not the use case

import Foundation

public protocol Injectable {
    static var shouldMock: Bool { get }
    static func create(_ isMock: Bool) -> Self
}

public extension Injectable {
    static var shouldMock: Bool { Environment.current == .testing }
}

@propertyWrapper
public class Inject<Value: Injectable> {
    private var storedValue: Value?
    
    public var wrappedValue: Value {
        get {
            guard let storedValue = storedValue else {
                return self.initializeValue()
            }
            
            return storedValue
        }
    }
    
    public init() {}
    
    private func initializeValue() -> Value {
        let value = Value.create(Value.shouldMock)
        self.storedValue = value
        return value
    }
}


// MARK: - Scratch
protocol SomeService {
    func doStuff()
    func doOtherStuff()
}

struct SomeServiceProvider: SomeService {
    func doStuff() { print("do stuff") }
    func doOtherStuff() { print("do other stuff") }
}

struct SomeServiceMock: SomeService {
    func doStuff() { print("mock stuff") }
    func doOtherStuff() { print("mock other stuff") }
}
