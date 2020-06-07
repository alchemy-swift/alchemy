@propertyWrapper
public class Inject<Value: Fusable> {
    // Just a single, global container for now. Would be great to have the user insert a custom container,
    // ideally like @Inject(container: self.container) but there is not a way to access self in a property
    // wrapper init, yet.
    //
    // See: https://stackoverflow.com/questions/58079611/access-self-in-swift-5-1-property-wrappers
    //
    // Maybe workaroud here?
    // https://forums.swift.org/t/property-wrappers-access-to-both-enclosing-self-and-wrapper-instance/32526
    private var container: Container = .global
    private var storedValue: Value?
    private var erasedResolver: (Container) throws -> Value
    
    public var wrappedValue: Value {
        get {
            guard let storedValue = storedValue else {
                // Someday, property wrappers will be able to throw and we won't need to fatal error out.
                // Though a fatal error might not be a bad idea; the program probably shouldn't run with
                // misconfigured dependencies.
                do {
                    return try self.initializeValue()
                } catch {
                    fatalError("Error resolving this service: \(error)")
                }
            }
            
            return storedValue
        }
    }
    
    // Only here so the compiler doesn't hurt itself and require `()` after the `@Inject`. Convenience inits
    // will override.
    public init() {
        fatalError("This should never be called.")
    }
    
    init(erasedResolver: @escaping (Container) throws -> Value) {
        self.erasedResolver = erasedResolver
    }
    
    private func initializeValue() throws -> Value {
        let value = try self.erasedResolver(self.container)
        self.storedValue = value
        return value
    }
}
