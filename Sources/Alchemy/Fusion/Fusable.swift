/// A type that can be injected via `@Fuse`.
public protocol Fusable {
    /// Setup the dependency inside a container.
    static func register(in container: Container) throws
}

@propertyWrapper
public class Fuse<Value: Fusable> {
    // Just a single, global container for now. Would be great to have the user insert a custom container,
    // ideally like @Fuse(container: self.container) but there is not a way to access self in a property
    // wrapper init, yet.
    //
    // See: https://stackoverflow.com/questions/58079611/access-self-in-swift-5-1-property-wrappers
    //
    // Maybe workaroud here?
    // https://forums.swift.org/t/property-wrappers-access-to-both-enclosing-self-and-wrapper-instance/32526
    private var container: Container = .global
    private var storedValue: Value?
    private var identifier: String?
    
    public var wrappedValue: Value {
        get {
            guard let storedValue = storedValue else {
                return self.initializeValue()
            }
            
            return storedValue
        }
    }
    
    public init() {}
    
    public init(_ identifier: String?) {
        self.identifier = identifier
    }
    
    private func initializeValue() -> Value {
        // Someday, property wrappers will be able to throw and we won't need to fatal error out. Though a
        // fatal might not be a bad idea; shouldn't let the program run with misconfigured dependencies.
        do {
            let value = try self.container.resolve(Value.self, identifier: self.identifier)
            self.storedValue = value
            return value
        } catch {
            fatalError("Error resolving this service: \(error)")
        }
    }
}
