import AlchemyTest

final class ApplicationTLSTests: TestCase<TestApp> {
    func testConfigureTLS() throws {
        XCTAssertNil(app.tlsConfig)
        let (key, cert) = generateFakeTLSCertificate()
        try app.useHTTPS(key: key, cert: cert)
        XCTAssertNotNil(app.tlsConfig)
    }
}
