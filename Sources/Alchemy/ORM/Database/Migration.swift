import Foundation

// Nonnull -> Use swift optional
// Unique
// Primary Key -> Identifiable?
// Foreign Key
// Check
// Default
// Index

@propertyWrapper
struct Unique<T>: Codable where T: Codable {
    var wrappedValue: T
}

@propertyWrapper
struct Index<T>: Codable where T: Codable {
    var wrappedValue: T
}

@propertyWrapper
struct Default<T>: Codable where T: Codable {
    var wrappedValue: T
}

@propertyWrapper
struct Check<T>: Codable where T: Codable {
    var wrappedValue: T
}

