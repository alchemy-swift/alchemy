import NIOSSL

extension TLSConfiguration {
    static func makeServerConfiguration(key: String, cert: String) throws -> TLSConfiguration {
        let chain = try NIOSSLCertificate.fromPEMFile(cert).map { NIOSSLCertificateSource.certificate($0) }
        let key = try NIOSSLPrivateKey(file: key, format: .pem)
        return TLSConfiguration.makeServerConfiguration(certificateChain: chain, privateKey: .privateKey(key))
    }
}
