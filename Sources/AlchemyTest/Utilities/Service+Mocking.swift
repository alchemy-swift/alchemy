extension Service {
    @discardableResult
    public static func mock(_ value: Self, id: Identifier? = nil) -> Self {
        Container.register(value, id: id).singleton()
        return value
    }
}
