protocol FusableResolver {
    func getValue(for identifier: String?) throws -> Fusable
}

extension FusableResolver {
    func getTypedValue<T: Fusable>(for identifier: String?) throws -> T {
        guard let typedValue = try self.getValue(for: identifier) as? T else {
            throw FusionError.registeredServiceTypeMismatch
        }
        
        return typedValue
    }
}
