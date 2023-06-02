@testable
import Alchemy
import XCTest

final class RelationshipMapperTests: XCTestCase {
    func testGetSet() {
        let mapper = RelationshipMapper<MapperModel>()
        XCTAssertEqual(mapper.getConfig(for: \.$belongsTo), .defaultBelongsTo())
        XCTAssertEqual(mapper.getConfig(for: \.$hasMany), .defaultHas())
        XCTAssertEqual(mapper.getConfig(for: \.$hasOne), .defaultHas())
        let defaultHas = mapper.getConfig(for: \.$hasOne)
        XCTAssertEqual(defaultHas.fromKey, "id")
        XCTAssertEqual(defaultHas.toKey, "mapper_model_id")
        let val = mapper.config(\.$hasOne)
            .from("foo")
            .to("bar")
        XCTAssertNotEqual(mapper.getConfig(for: \.$hasOne), .defaultHas())
        XCTAssertEqual(mapper.getConfig(for: \.$hasOne), val)
        XCTAssertEqual(val.fromKey, "foo")
        XCTAssertEqual(val.toKey, "bar")
    }
    
    func testHasThrough() {
        let mapper = RelationshipMapper<MapperModel>()
        let mapping = mapper.config(\.$hasMany).through("foo", from: "bar", to: "baz")
        let expected = RelationshipMapping<MapperModel, MapperModel>(
            .has,
            fromTable: "mapper_models",
            fromKey: "id",
            toTable: "mapper_models",
            toKey: "foo_id",
            through: .init(
                table: "foo",
                fromKey: "bar",
                toKey: "baz"))
        XCTAssertEqual(mapping, expected)
        let mappingDefault = mapper.config(\.$hasMany).through("foo")
        XCTAssertEqual(mappingDefault.through?.fromKey, "mapper_model_id")
        XCTAssertEqual(mappingDefault.through?.toKey, "id")
    }
    
    func testBelongsThrough() {
        let mapper = RelationshipMapper<MapperModel>()
        let mapping = mapper.config(\.$belongsTo).through("foo", from: "bar", to: "baz")
        let expected = RelationshipMapping<MapperModel, MapperModel>(
            .belongs,
            fromTable: "mapper_models",
            fromKey: "foo_id",
            toTable: "mapper_models",
            toKey: "id",
            through: .init(
                table: "foo",
                fromKey: "bar",
                toKey: "baz"))
        XCTAssertEqual(mapping, expected)
        let mappingDefault = mapper.config(\.$belongsTo).through("foo")
        XCTAssertEqual(mappingDefault.through?.fromKey, "id")
        XCTAssertEqual(mappingDefault.through?.toKey, "mapper_model_id")
    }
    
    func testThroughPivot() {
        let mapper = RelationshipMapper<MapperModel>()
        let mapping = mapper.config(\.$hasMany).throughPivot("foo", from: "bar", to: "baz")
        let expected = RelationshipMapping<MapperModel, MapperModel>(
            .has,
            fromTable: "mapper_models",
            fromKey: "id",
            toTable: "mapper_models",
            toKey: "id",
            through: .init(
                table: "foo",
                fromKey: "bar",
                toKey: "baz"))
        XCTAssertEqual(mapping, expected)
    }
}

struct MapperModel: Model {
    var id: PK<Int> = .new
    
    @BelongsTo var belongsTo: MapperModel
    @BelongsTo var belongsToOptional: MapperModel?
    @HasOne    var hasOne: MapperModel
    @HasOne    var hasOneOptional: MapperModel?
    @HasMany   var hasMany: [MapperModel]
}
