import NIOSSL
import NIOHTTP1

extension Application {
    /// Any tls configuration for this application. TLS can be configured using
    /// `Application.useHTTPS(...)` or `Application.useHTTP2(...)`.
    public var tlsConfig: TLSConfiguration? {
        @Inject var config: ServerConfiguration
        return config.tlsConfig
    }
    
    /// Use HTTPS when serving.
    ///
    /// - Parameters:
    ///   - key: The path to the private key.
    ///   - cert: The path of the cert.
    /// - Throws: Any errors encountered when accessing the certs.
    public func useHTTPS(key: String, cert: String) throws {
        useHTTPS(tlsConfig: try .makeServerConfiguration(key: key, cert: cert))
    }
    
    /// Use HTTPS when serving.
    ///
    /// - Parameter tlsConfig: A raw NIO `TLSConfiguration` to use.
    public func useHTTPS(tlsConfig: TLSConfiguration) {
        @Inject var config: ServerConfiguration
        config.tlsConfig = tlsConfig
    }
}
