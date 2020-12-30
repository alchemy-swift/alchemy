import XCTest
@testable import Papyrus

final class EncodingTests: XCTestCase {
    func testEncodeValue() throws {
        let testAPI = TestAPI()
        let testObj = SomeJSON(string: "foo", int: 1)
        let reqDTO = TestReqDTO(userID: "1234", number: 1, someThings: [], value: "test", obj: testObj)
        let params = try testAPI.post.parameters(dto: reqDTO)
        XCTAssert(params.fullPath.hasPrefix("/v1/accounts/1234/transfer"))
        XCTAssert(params.fullPath.hasSuffix("?number=1"))
        XCTAssert(params.method == .post)
        
        /// Todo data test
    }
}
