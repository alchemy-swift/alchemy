import Foundation

/// Represents a dynamic parameter inside the URL. Something like `:user_id` in the path `/v1/users/:user_id`.
public struct PathParameter: Equatable {
    /// The escaped parameter that was matched. Something like `:user_id`
    public let parameter: String
    /// The actual string value of the parameter.
    public let stringValue: String
}

extension PathParameter {
    public struct Error: Swift.Error {
        public let message: String
    }
    
    /// Decodes a `UUID` from this parameter's value or throws a `PathParameter.Error`.
    public func uuid() throws -> UUID {
        try UUID(uuidString: self.stringValue)
            .unwrap(or: Error(message: "Unable to decode UUID for '\(self.parameter)'. Value was '\(self.stringValue)'."))
    }

    /// Returns the string value of this parameter.
    public func string() -> String {
        self.stringValue
    }
    
    /// Decodes an `Int` from this parameter's value or throws a `PathParameter.Error`.
    public func int() throws -> Int {
        try Int(self.stringValue)
            .unwrap(or: Error(message: "Unable to decode Int for '\(self.parameter)'. Value was '\(self.stringValue)'."))
    }
}

extension Optional {
    func unwrap(or error: Error) throws -> Wrapped {
        guard let wrapped = self else {
            throw error
        }
        
        return wrapped
    }
}
