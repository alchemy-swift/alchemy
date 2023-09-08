import NIOSSL
import HummingbirdCore
import HummingbirdHTTP2
import HummingbirdTLS

extension Application {
    
    // MARK: HTTP2

    /// Use HTTP/2 when serving, over TLS with the given key and cert.
    ///
    /// - Parameters:
    ///   - key: The path to the private key.
    ///   - cert: The path of the cert.
    /// - Throws: Any errors encountered when accessing the certs.
    public func useHTTP2(key: String, cert: String) throws {
        try useHTTP2(tlsConfig: .makeServerConfiguration(key: key, cert: cert))
    }
    
    /// Use HTTP/2 when serving, over TLS with the given tls config.
    ///
    /// - Parameter tlsConfig: A raw NIO `TLSConfiguration` to use.
    public func useHTTP2(tlsConfig: TLSConfiguration) throws {
        try server.addHTTP2Upgrade(tlsConfiguration: tlsConfig)
    }

    // MARK: HTTPS

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
