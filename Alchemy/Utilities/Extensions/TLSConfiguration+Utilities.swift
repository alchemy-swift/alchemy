import NIOSSL

extension TLSConfiguration {
    static func makeServerConfiguration(key: String, cert: String) throws -> TLSConfiguration {
        TLSConfiguration.makeServerConfiguration(
            certificateChain: try NIOSSLCertificate
                .fromPEMFile(cert)
                .map { NIOSSLCertificateSource.certificate($0) },
            privateKey: .file(key))
    }
}
