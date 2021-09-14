import NIOSSL

/// Settings for how this server should talk to clients.
public final class ApplicationConfiguration: Service {
    /// Any TLS configuration for serving over HTTPS.
    public var tlsConfig: TLSConfiguration?
    /// The HTTP protocol versions supported. Defaults to `HTTP/1.1`.
    public var httpVersions: [HTTPVersion] = [.http1_1]
}

extension Application {
    /// Use HTTPS when serving.
    ///
    /// - Parameters:
    ///   - key: The path to the private key.
    ///   - cert: The path of the cert.
    /// - Throws: Any errors encountered when accessing the certs.
    public func useHTTPS(key: String, cert: String) throws {
        let config = Container.resolve(ApplicationConfiguration.self)
        config.tlsConfig = TLSConfiguration
            .makeServerConfiguration(
                certificateChain: try NIOSSLCertificate
                    .fromPEMFile(cert)
                    .map { NIOSSLCertificateSource.certificate($0) },
                privateKey: .file(key))
    }
    
    /// Use HTTPS when serving.
    ///
    /// - Parameter tlsConfig: A raw NIO `TLSConfiguration` to use.
    public func useHTTPS(tlsConfig: TLSConfiguration) {
        let config = Container.resolve(ApplicationConfiguration.self)
        config.tlsConfig = tlsConfig
    }
    
    /// Use HTTP/2 when serving, over TLS with the given key and cert.
    ///
    /// - Parameters:
    ///   - key: The path to the private key.
    ///   - cert: The path of the cert.
    /// - Throws: Any errors encountered when accessing the certs.
    public func useHTTP2(key: String, cert: String) throws {
        let config = Container.resolve(ApplicationConfiguration.self)
        config.httpVersions = [.http2, .http1_1]
        try useHTTPS(key: key, cert: cert)
    }
    
    /// Use HTTP/2 when serving, over TLS with the given tls config.
    ///
    /// - Parameter tlsConfig: A raw NIO `TLSConfiguration` to use.
    public func useHTTP2(tlsConfig: TLSConfiguration) {
        let config = Container.resolve(ApplicationConfiguration.self)
        config.httpVersions = [.http2, .http1_1]
        useHTTPS(tlsConfig: tlsConfig)
    }
}
