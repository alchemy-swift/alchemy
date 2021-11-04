import NIOSSL
import NIOHTTP1

extension Application {
    /// The http versions this application supports. By default, your
    /// application will support `HTTP/1.1` but you may also support
    /// `HTTP/2` with `Application.useHTTP2(...)`.
    public var httpVersions: [HTTPVersion] {
        @Inject var config: ServerConfiguration
        return config.httpVersions
    }
    
    /// Use HTTP/2 when serving, over TLS with the given key and cert.
    ///
    /// - Parameters:
    ///   - key: The path to the private key.
    ///   - cert: The path of the cert.
    /// - Throws: Any errors encountered when accessing the certs.
    public func useHTTP2(key: String, cert: String) throws {
        useHTTP2(tlsConfig: try .makeServerConfiguration(key: key, cert: cert))
    }
    
    /// Use HTTP/2 when serving, over TLS with the given tls config.
    ///
    /// - Parameter tlsConfig: A raw NIO `TLSConfiguration` to use.
    public func useHTTP2(tlsConfig: TLSConfiguration) {
        @Inject var config: ServerConfiguration
        config.httpVersions = [.http2, .http1_1]
        useHTTPS(tlsConfig: tlsConfig)
    }
}
