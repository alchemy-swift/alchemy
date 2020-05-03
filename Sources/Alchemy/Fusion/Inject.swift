public protocol IdentifiableService {
    associatedtype Identifier
    static var shouldMock: Bool { get }
    static func create(identifier: Identifier?, _ isMock: Bool) -> Self
}

public protocol Injectable {
    associatedtype Identifier
    static var shouldMock: Bool { get }
    static func create(identifier: Identifier?, _ isMock: Bool) -> Self
}

public extension Injectable {
    static var shouldMock: Bool { Environment.current == .testing }
}

@propertyWrapper
public class Inject<Value: Injectable> {
    private var storedValue: Value?
    private var identifier: Value.Identifier?
    
    public var wrappedValue: Value {
        get {
            guard let storedValue = storedValue else {
                return self.initializeValue()
            }
            
            return storedValue
        }
    }
    
    public init() {}
    
    public init(_ identifier: Value.Identifier?) {
        self.identifier = identifier
    }
    
    private func initializeValue() -> Value {
        let value = Value.create(identifier: self.identifier, Value.shouldMock)
        self.storedValue = value
        return value
    }
}

/// How to get this to work nicely with protocols?
/// eg....
/// protocol SomeService { ... }
/// protocol SomeServiceProvider: SomeService { ... }
/// protocol SomeServiceMock: SomeService { ... }

// Use cases
// 1. A singleton, i.e. a redis cache.
// 2. One of a few, i.e. there are multiple databases.
// 3. Varies on the fly, i.e. a specific ViewModel. // probably not the use case

/// TODO
/// 1. Thread Safety
/// 2. Ensure no retain cycles / things deallocate properly
/// 3. `Error`s instead of `fatalErrors()`?
/// 4. Custom identifier types?
/// 5. Type safety around identifiers? (i.e. don't allow `@Fuse("someID")` if it's not an `IdentifiableSingleton`)
