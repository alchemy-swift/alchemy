import Foundation

/// Used for providing thread safe access to a property.
@propertyWrapper
public struct Locked<T> {
    /// The threadsafe accessor for this property.
    public var wrappedValue: T {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.value
        }
        set {
            self.lock.lock()
            defer { self.lock.unlock() }
            self.value = newValue
        }
    }
    
    /// The underlying value of this property.
    private var value: T
    
    /// The lock to protect this property.
    private let lock = NSRecursiveLock()
    
    /// Initialize with the given value.
    ///
    /// - Parameter wrappedValue: The value.
    public init(wrappedValue: T) {
        self.value = wrappedValue
    }
}
