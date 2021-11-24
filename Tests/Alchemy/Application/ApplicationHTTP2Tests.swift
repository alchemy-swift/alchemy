import AlchemyTest

final class ApplicationHTTP2Tests: TestCase<TestApp> {
    func testConfigureHTTP2() throws {
        XCTAssertNil(app.tlsConfig)
        XCTAssertEqual(app.httpVersions, [.http1_1])
        let (key, cert) = generateFakeTLSCertificate()
        try app.useHTTP2(key: key, cert: cert)
        XCTAssertNotNil(app.tlsConfig)
        XCTAssertTrue(app.httpVersions.contains(.http1_1) && app.httpVersions.contains(.http2))
    }
}
