import Foundation

/// Represents a dynamic parameter inside the path. Parameter
/// placeholders should be prefaced with a colon (`:`) in
/// the route string. Something like `:user_id` in the
/// path `/v1/users/:user_id`.
public struct Parameter: Equatable {
    /// An error encountered while decoding a path parameter value
    /// string to a specific type such as `UUID` or `Int`.
    public struct DecodingError: Error {
        public let message: String
        init(_ message: String) { self.message = message }
    }
    
    /// The escaped parameter that was matched, _without_ the colon.
    /// Something like `user_id` if `:user_id` was in the path.
    public let key: String
    /// The actual string value of the parameter.
    public let value: String
    
    /// Decodes a `UUID` from this parameter's value or throws if the
    /// string is an invalid `UUID`.
    ///
    /// - Throws: A `Parameter.DecodingError` if the value string
    ///   is not convertible to a `UUID`.
    /// - Returns: The decoded `UUID`.
    public func uuid() throws -> UUID {
        try UUID(uuidString: value)
            .unwrap(or: DecodingError("Unable to decode UUID for '\(key)'. Value was '\(value)'."))
    }

    /// Returns the `String` value of this parameter.
    ///
    /// - Returns: the value of this parameter.
    public func string() -> String {
        value
    }
    
    /// Decodes an `Int` from this parameter's value or throws if the
    /// string can't be converted to an `Int`.
    ///
    /// - Throws: a `Parameter.DecodingError` if the value string
    ///   is not convertible to a `Int`.
    /// - Returns: the decoded `Int`.
    public func int() throws -> Int {
        try Int(value)
            .unwrap(or: DecodingError("Unable to decode Int for '\(key)'. Value was '\(value)'."))
    }
}
