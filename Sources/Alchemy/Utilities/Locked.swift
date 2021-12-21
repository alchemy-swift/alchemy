import Foundation
import NIOConcurrencyHelpers

/// Used for providing thread safe access to a property. Doesn't work on
/// collections.
@propertyWrapper
public struct Locked<T> {
    /// The threadsafe accessor for this property.
    public var wrappedValue: T {
        get { lock.withLock { value } }
        set { lock.withLock { value = newValue } }
    }
    
    /// The underlying value of this property.
    private var value: T
    /// The lock to protect this property.
    private let lock = Lock()
    
    /// Initialize with the given value.
    ///
    /// - Parameter wrappedValue: The value.
    public init(wrappedValue: T) {
        self.value = wrappedValue
    }
}
