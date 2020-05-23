@testable import Alchemy

struct TestAPI {
    @POST("/v1/accounts/{userID}/transfer")
    var test: Endpoint<TestReqDTO, TestResDTO>
}

struct TestReqDTO {
    @Path   var userID: String
    @HTTPQuery  var number: Int
    @HTTPQuery  var someThings: [String]
    @Header var value: String
    @Body   var obj: TestObj
}

struct TestResDTO: Codable {
    let string: String
}

struct TestObj: Codable {
    var thing: String
}
