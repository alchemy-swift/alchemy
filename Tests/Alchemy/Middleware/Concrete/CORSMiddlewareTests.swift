@testable
import Alchemy
import AlchemyTest

final class CORSMiddlewareTests: TestCase<TestApp> {
    func testDefault() async throws {
        let cors = CORSMiddleware()
        app.useAll(cors)
        
        try await Test.get("/hello")
            .assertHeaderMissing("Access-Control-Allow-Origin")
        
        try await Test.withHeader("Origin", value: "https://foo.example")
            .get("/hello")
            .assertHeader("Access-Control-Allow-Origin", value: "https://foo.example")
            .assertHeader("Access-Control-Allow-Headers", value: "Accept, Authorization, Content-Type, Origin, X-Requested-With")
            .assertHeader("Access-Control-Allow-Methods", value: "GET, POST, PUT, OPTIONS, DELETE, PATCH")
            .assertHeader("Access-Control-Max-Age", value: "600")
            .assertHeaderMissing("Access-Control-Expose-Headers")
            .assertHeaderMissing("Access-Control-Allow-Credentials")
    }
    
    func testCustom() async throws {
        let cors = CORSMiddleware(configuration: .init(
            allowedOrigin: .originBased,
            allowedMethods: [.GET, .POST],
            allowedHeaders: ["foo", "bar"],
            allowCredentials: true,
            cacheExpiration: 123,
            exposedHeaders: ["baz"]
        ))
        app.useAll(cors)
        
        try await Test.get("/hello")
            .assertHeaderMissing("Access-Control-Allow-Origin")
        
        try await Test.withHeader("Origin", value: "https://foo.example")
            .get("/hello")
            .assertHeader("Access-Control-Allow-Origin", value: "https://foo.example")
            .assertHeader("Access-Control-Allow-Headers", value: "foo, bar")
            .assertHeader("Access-Control-Allow-Methods", value: "GET, POST")
            .assertHeader("Access-Control-Expose-Headers", value: "baz")
            .assertHeader("Access-Control-Max-Age", value: "123")
            .assertHeader("Access-Control-Allow-Credentials", value: "true")
    }
    
    func testPreflight() async throws {
        let cors = CORSMiddleware()
        app.useAll(cors)
        
        try await Test.options("/hello")
            .assertHeaderMissing("Access-Control-Allow-Origin")
        
        try await Test.withHeader("Origin", value: "https://foo.example")
            .withHeader("Access-Control-Request-Method", value: "PUT")
            .options("/hello")
            .assertOk()
            .assertHeader("Access-Control-Allow-Origin", value: "https://foo.example")
            .assertHeader("Access-Control-Allow-Headers", value: "Accept, Authorization, Content-Type, Origin, X-Requested-With")
            .assertHeader("Access-Control-Allow-Methods", value: "GET, POST, PUT, OPTIONS, DELETE, PATCH")
            .assertHeader("Access-Control-Max-Age", value: "600")
            .assertHeaderMissing("Access-Control-Expose-Headers")
            .assertHeaderMissing("Access-Control-Allow-Credentials")
    }
    
    func testOriginSettings() {
        let origin = "https://foo.example"
        XCTAssertEqual(CORSMiddleware.AllowOriginSetting.none.header(forOrigin: origin), "")
        XCTAssertEqual(CORSMiddleware.AllowOriginSetting.originBased.header(forOrigin: origin), origin)
        XCTAssertEqual(CORSMiddleware.AllowOriginSetting.all.header(forOrigin: origin), "*")
        XCTAssertEqual(CORSMiddleware.AllowOriginSetting.any([origin]).header(forOrigin: origin), origin)
        XCTAssertEqual(CORSMiddleware.AllowOriginSetting.any(["foo"]).header(forOrigin: origin), "")
        XCTAssertEqual(CORSMiddleware.AllowOriginSetting.custom(origin).header(forOrigin: origin), origin)
    }
}
