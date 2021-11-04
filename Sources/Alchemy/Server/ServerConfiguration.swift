import NIOSSL

/// Settings for how this server should talk to clients.
final class ServerConfiguration: Service {
    /// Any TLS configuration for serving over HTTPS.
    var tlsConfig: TLSConfiguration?
    /// The HTTP protocol versions supported. Defaults to `HTTP/1.1`.
    var httpVersions: [HTTPVersion] = [.http1_1]
}
