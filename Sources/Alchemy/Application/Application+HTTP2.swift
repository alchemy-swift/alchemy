import NIOSSL
import NIOHTTP1
import Hummingbird
import HummingbirdHTTP2

extension Application {
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
        @Inject var app: HBApplication
        try app.server.addHTTP2Upgrade(tlsConfiguration: tlsConfig)
    }
}
