import AlchemyTesting

extension Trait where Self == MockAppTrait<TestApp> {
    static var mockTestApp: Self { Self() }
}
