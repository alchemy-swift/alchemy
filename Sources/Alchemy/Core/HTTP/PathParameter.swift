import Foundation

/// Represents a dynamic parameter inside the URL. Parameter
/// placeholders should be prefaced with a colon (`:`) in
/// the route string. Something like `:user_id` in the
/// path `/v1/users/:user_id`.
public struct PathParameter: Equatable {
    /// An error encountered while decoding a path parameter value
    /// string to a specific type such as `UUID` or `Int`.
    public struct DecodingError: Error {
        public let message: String
        init(_ message: String) { self.message = message }
    }
    
    /// The escaped parameter that was matched, _without_ the colon.
    /// Something like `user_id` if `:user_id` was in the path.
    public let parameter: String
    /// The actual string value of the parameter.
    public let stringValue: String
    
    /// Decodes a `UUID` from this parameter's value or throws if the
    /// string is an invalid `UUID`.
    ///
    /// - Throws: A `PathParameter.DecodingError` if the value string
    ///   is not convertible to a `UUID`.
    /// - Returns: The decoded `UUID`.
    public func uuid() throws -> UUID {
        try UUID(uuidString: self.stringValue)
            .unwrap(or: DecodingError("Unable to decode UUID for '\(self.parameter)'. Value was '\(self.stringValue)'."))
    }

    /// Returns the `String` value of this parameter.
    ///
    /// - Returns: the value of this parameter.
    public func string() -> String {
        self.stringValue
    }
    
    /// Decodes an `Int` from this parameter's value or throws if the
    /// string can't be converted to an `Int`.
    ///
    /// - Throws: a `PathParameter.DecodingError` if the value string
    ///   is not convertible to a `Int`.
    /// - Returns: the decoded `Int`.
    public func int() throws -> Int {
        try Int(self.stringValue)
            .unwrap(or: DecodingError("Unable to decode Int for '\(self.parameter)'. Value was '\(self.stringValue)'."))
    }
}
