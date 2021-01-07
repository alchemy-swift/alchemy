@testable import Papyrus

final class TestAPI: EndpointGroup {
    @POST("/foo/:path1/bar")
    var post: Endpoint<TestRequest, Empty>
    
    @PUT("/body")
    var urlBody: Endpoint<TestURLBody, Empty>
    
    @POST("/multiple")
    var multipleBodies: Endpoint<MultipleBodies, Empty>
    
    @GET("/query")
    var queryCodable: Endpoint<TestQueryCodable, Empty>
    
    @DELETE("/delete")
    var delete: Endpoint<Empty, Empty>
    
    @PATCH("/patch")
    var patch: Endpoint<Empty, Empty>
    
    @CUSTOM(method: "CONNECT", "/connect")
    var custom: Endpoint<Empty, Empty>
}

struct TestRequest: EndpointRequest {
    @Path
    var path1: String
    
    @URLQuery
    var query1: Int
    
    @URLQuery
    var query2: String?
    
    @URLQuery
    var query3: String?
    
    @URLQuery
    var query4: [String]
    
    @URLQuery
    var query5: [String]
    
    @URLQuery
    var query6: Bool?
    
    @URLQuery
    var query7: Bool
    
    @Header
    var header1: String
    
    @Body
    var body: SomeJSON
}

struct TestURLBody: EndpointRequest {
    static var bodyEncoding: BodyEncoding = .urlEncoded
    
    @Body
    var body: SomeJSON
    
    init(body: SomeJSON) {
        self.body = body
    }
}

struct TestQueryCodable: EndpointRequest {
    @URLQuery
    var body: SomeJSON
}

struct MultipleBodies: EndpointRequest {
    @Body
    var body1 = SomeJSON(string: "foo", int: 0)
    
    @Body
    var body2 = SomeJSON(string: "bar", int: 1)
}

struct SomeJSON: Codable {
    var string: String
    var int: Int
}
