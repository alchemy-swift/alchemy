@testable import Papyrus

struct TestAPI {
    @POST("/v1/accounts/:userID/transfer")
    var post: Endpoint<TestReqDTO, TestResDTO>
    
    @GET("/get")
    var get: Endpoint<Empty, Empty>
    
    @DELETE("/get")
    var delete: Endpoint<Empty, Empty>
    
    @PUT("/get")
    var put: Endpoint<Empty, Empty>
    
    @PATCH("/get")
    var patch: Endpoint<Empty, Empty>
    
    @CUSTOM(method: "CONNECT", "/connect")
    var custom: Endpoint<Empty, Empty>
}

struct TestReqDTO: EndpointRequest {
    @Path
    var userID: String
    
    @URLQuery
    var number: Int
    
    @URLQuery
    var someThings: [String]
    
    @Header
    var value: String
    
    @Body
    var obj: SomeJSON
}

struct SomeJSON: Codable {
    var string: String
    var int: Int
}

struct TestResDTO: Codable {
    let string: String
}
