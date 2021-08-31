import Foundation
import NIO

extension BCryptDigest {
    /// Asynchronously hashes a password on a separate thread.
    ///
    /// - Parameter password: The password to hash.
    /// - Returns: A future containing the hashed password that will
    ///   resolve on the initiating `EventLoop`.
    public func hashAsync(_ password: String) -> EventLoopFuture<String> {
        Thread.run { try Bcrypt.hash(password) }
    }
    
    /// Asynchronously verifies a password & hash on a separate
    /// thread.
    ///
    /// - Parameters:
    ///   - plaintext: The plaintext password.
    ///   - hashed: The hashed password to verify with.
    /// - Returns: A future containing a `Bool` indicating whether the
    ///   password and hash matched. This will resolve on the
    ///   initiating `EventLoop`.
    public func verifyAsync(plaintext: String, hashed: String) -> EventLoopFuture<Bool> {
        Thread.run { try Bcrypt.verify(plaintext, created: hashed) }
    }
}
