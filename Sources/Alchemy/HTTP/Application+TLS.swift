import NIOSSL
import NIOHTTP1
import HummingbirdTLS
import HummingbirdCore

extension Application {
    /// Use HTTPS when serving.
    ///
    /// - Parameters:
    ///   - key: The path to the private key.
    ///   - cert: The path of the cert.
    /// - Throws: Any errors encountered when accessing the certs.
    public func useHTTPS(key: String, cert: String) throws {
        try useHTTPS(tlsConfig: .makeServerConfiguration(key: key, cert: cert))
    }
    
    /// Use HTTPS when serving.
    ///
    /// - Parameter tlsConfig: A raw NIO `TLSConfiguration` to use.
    public func useHTTPS(tlsConfig: TLSConfiguration) throws {
        try server.addTLS(tlsConfiguration: tlsConfig)
    }
}
