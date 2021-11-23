@testable
import Alchemy
import XCTest

final class RelationshipTests: XCTestCase {
    func testModelMaybeOptional() throws {
        let nilModel: TestModel? = nil
        let doubleOptionalNilModel: TestModel?? = nil
        XCTAssertEqual(nilModel.id, nil)
        XCTAssertEqual(try Optional<TestModel>.from(nilModel), nil)
        XCTAssertEqual(try Optional<TestModel>.from(doubleOptionalNilModel), nil)
        
        let optionalModel: TestModel? = TestModel(id: 1)
        let doubleOptionalModel: TestModel?? = TestModel(id: 1)
        XCTAssertEqual(optionalModel.id, 1)
        XCTAssertEqual(try Optional<TestModel>.from(optionalModel), optionalModel)
        XCTAssertEqual(try Optional<TestModel>.from(doubleOptionalModel), optionalModel)
        
        let model: TestModel = TestModel(id: 1)
        XCTAssertEqual(model.id, 1)
        XCTAssertEqual(try TestModel.from(model), model)
        XCTAssertThrowsError(try TestModel.from(nil))
    }
}

private struct TestModel: Model, Equatable {
    var id: Int?
}
