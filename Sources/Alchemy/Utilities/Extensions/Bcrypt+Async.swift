import Foundation
import NIO

extension BCryptDigest {
    /// Asynchronously hashes a password on a separate thread.
    ///
    /// - Parameter password: The password to hash.
    /// - Returns: The hashed password.
    public func hashAsync(_ password: String) async throws -> String {
        try await Thread.run { try Bcrypt.hash(password) }
    }
    
    /// Asynchronously verifies a password & hash on a separate
    /// thread.
    ///
    /// - Parameters:
    ///   - plaintext: The plaintext password.
    ///   - hashed: The hashed password to verify with.
    /// - Returns: Whether the password and hash matched.
    public func verifyAsync(plaintext: String, hashed: String) async throws -> Bool {
        try await Thread.run { try Bcrypt.verify(plaintext, created: hashed) }
    }
}
